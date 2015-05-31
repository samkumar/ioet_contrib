from smap import driver, actuate, util
import msgpack
import socket
import requests
import json
import collections

manifest_url = "https://raw.githubusercontent.com/UCB-IoET/svc/master/manifest.json"

UDP_IP = "::"
PREFIX = "2001:470:4956:2:212:6d02::"

"""
We receive messages from firestorms, which are tuples of
(data, nodeid, attribute id)
- data will be msgpack
- nodeid will be a string
- attribute id will be a hex number that should be unique to file:
    https://github.com/UCB-IoET/svc/raw/master/manifest.json
  and will tell us how to treat the msgpack data

This server will take each incoming message, decode the msgpack data, and then lookup in a big json file what the corresponding
sMAP metadata is for that (nodeid, attr id) tuple, and then send it to the sMAP archiver
"""

# recursive dict update from http://stackoverflow.com/questions/3232943/update-value-of-a-nested-dictionary-of-varying-depth
def update(d, upd):
    for k,v in upd.iteritems():
        if isinstance(v, collections.Mapping):
            r = update(d.get(k, {}), v)
            d[k] = r
        else:
            d[k] = upd[k]
    return d

class Middleware(driver.SmapDriver):
    def setup(self, opts):
        self.listenPort = int(opts.get('listenPort', 9001))

        self.archiver = opts.get('archiver','http://localhost:8079')

        # pull the SVC manifest and load the json manifest from the local file
        self.pullManifests()

        self.addedTimeseries = set()

        # now set up socket
        self.sock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
        self.sock.bind((UDP_IP, self.listenPort))

        # nonblocking because HACK
        self.sock.setblocking(False)

    def start(self):
        # pull manifest every minute
        util.periodicSequentialCall(self.pullManifests).start(60)
        # poll socket every 100ms
        util.periodicSequentialCall(self.listen).start(.1)
    
    def pullManifests(self):
        self.smapManifest = json.load(open('smapManifest.json'))
        try:
            resp = requests.get(manifest_url)
            self.svcManifest = json.loads(resp.content)
            print 'pulled new svcManifest'
        except:
            pass
    
    def getDescription(self, attrid):
        """
        Given an attrid, we return the corresponding attribute dictionary and serviceID from SVC manifest
        """
        for name, service in self.svcManifest.iteritems():
            for attr, desc in service['attributes'].iteritems():
                if desc['id'] == attrid:
                    return service['id'], desc

    def decodeData(self, attrid, data):
        """
        Given an attrid, decodes data as per the description
        """
        _, desc = self.getDescription(attrid)
        firstdatatype = desc['format'][0][0]
        inttypes = [sign + size for sign in ['s','u'] for size in ['8','16']]
        # here is where we would decode non-numeric types
        if len(desc['format']) > 1:
            print 'is list'
        elif firstdatatype in inttypes:
            return float(data)
    
    def getSmapMessage(self, nodeid, attrid, reading):
        """
        This grabs the metadata description from the json smap manifest and performs
        all the inheritance and transformations to create valid sMAP metadata for the
        source. It then adds a new timeseries to this source (if one does not already exist)
        and constructs an attached actuator if the source needs one.
        Returns the path and the constructed sMAP object.
        This method is idempotent in regards to construction actuators and timeseries
        """
        if nodeid not in self.smapManifest: return '',{}
        obj = self.smapManifest.get(nodeid,None).copy()
        if not obj:
            return '',{}
        inherit = obj.pop('INHERIT') if 'INHERIT' in obj else []
        for section in inherit:
            obj = update(obj, self.smapManifest.get(section, {}))
        attrs = obj.pop('ATTRS') if 'ATTRS' in obj else {}
        upd = attrs.get(attrid, {}).copy()
        if 'Path' not in upd: return '',{}
        path = str(upd.pop('Path'))
        actuator = upd.pop('ACTUATOR') if 'ACTUATOR' in upd else ''
        obj = update(obj, upd)
        print path, self.addedTimeseries
        if path and path not in self.addedTimeseries:
            self.addedTimeseries.add(path)
            print 'GETTING MD for', path
            svcid, desc = self.getDescription(attrid)
            print desc
            ts = self.add_timeseries(path, desc['format'][0][1], data_type='double')
            if actuator == 'binary':
                ts.add_actuator(OnOffActuator(stormIP=PREFIX+nodeid, svcID=svcid, attrID=attrid, archiver=self.archiver))
            print dict(util.buildkv('', obj))
            self.set_metadata(path, dict(util.buildkv('', obj)))
        return path, {path: obj}

    def listen(self):
        try:
            # try to get data off the wire
            packeddata, addr = self.sock.recvfrom(1024)
            # unpack the SVCD data
            data, nodeid, attrid = msgpack.unpackb(packeddata)   
            print 'NODEID',nodeid,'ATTRID',hex(attrid)
            attrid = '{}'.format(hex(attrid))
            # decode the data
            reading = self.decodeData(attrid, data)
            # get the smap metadata + path
            path, smapObj = self.getSmapMessage(nodeid, attrid, reading)
            if not path: return
            print attrid, path, reading
            # add to the appropriate stream
            self.add(path, reading)

        except socket.error, e:
            if e == 'timed out':
                return


class FireStormActuator(actuate.SmapActuator):
    """
    This is a generic actuator class for all things Firestorm. Currently limited to the sMAP
    actuator classes (nstate, binary, continuous and continuousinteger -- all but binary have
    yet to be implemented, but this is trivial). Constructs the SVCD message and sends to the
    write SVCD port at 2526. CURRENTLY IGNORES IVKID CONFIRMATIONS
    """
    def __init__(self, **opts):
        self.stormIP = opts.get('stormIP')
        self.port = 2526 # write port on svc
        self.svcID = int(opts.get('svcID'), 16)
        self.attrID = int(opts.get('attrID'), 16)
        self.laststate = 0
        self.sock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
        self.sock.bind((UDP_IP, 0))
        actuate.SmapActuator.__init__(self, opts.get('archiver'))
        self.subscribe(opts.get('subscribe'))
        self.state = 0
        self.ivk_id = 0

    def write(self, data):
        print self.svcID, self.attrID, self.ivk_id, data
        try:
            svcWrite = msgpack.packb([self.svcID, self.attrID, self.ivk_id, data])
            self.ivk_id = (self.ivk_id + 1) & 65535
            self.sock.sendto(svcWrite, (self.stormIP, self.port))
        except Exception as e:
            print e
        
class OnOffActuator(FireStormActuator, actuate.BinaryActuator):
    def __init__(self, **opts):
        actuate.BinaryActuator.__init__(self)
        FireStormActuator.__init__(self, **opts)

    def get_state(self, request):
        return self.laststate

    def set_state(self, request, state):
        print 'ONOFF',state
        self.laststate = state
        self.write(state)
        return state
