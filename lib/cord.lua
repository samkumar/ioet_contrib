-------------------------------------
-- CORoutine Daemon (CORD)
-- this implements scheduled fibers
-------------------------------------

cord = {}

cord._coidx = 1
cord._activeidx = 1
cord._cors    = {}
cord._PROMISE = 1
cord._NORMAL  = 2
-- status a cord can be in
cord._READY   = 3
cord._AWAIT   = 4
cord._PROMISEDONE = 5

cord.new = function (f)
    local co = coroutine.create(f)
    cord._cors[cord._coidx] = {c=co,s=cord._READY }
    local handle = cord._coidx
    cord._coidx = cord._coidx + 1
    return handle
end

cord.await = function(f, ...)
    cord._cors[cord._activeidx].s = cord._AWAIT
    cord._cors[cord._activeidx].rv=nil
    local aidx = cord._activeidx
    local args = {...}
    args[#args+1] = function (...)
        cord._cors[aidx].s=cord._PROMISEDONE
        cord._cors[aidx].rv={...}
    end
    f(unpack(args))
    return coroutine.yield()
end

cord.enter_loop = function ()
    while true do
        local ranone = false
        for i,v in pairs(cord._cors) do
            if (v.s == cord._READY) then
                ranone = true
                cord._activeidx = i
                coroutine.resume(v.c)
                if (coroutine.status(v.c) == "dead" or v.k) then
                    cord._cors[i] = nil
                end
            elseif (v.s == cord._PROMISEDONE) then
                cord._activeidx = i;
                v.s = cord._READY
                coroutine.resume(v.c, unpack(v.rv))
                if (coroutine.status(v.c) == "dead" or v.k) then
                    cord._cors[i] = nil
                end
            end
        end
        storm.os.kyield()
        collectgarbage("collect")
        if ranone then
            storm.os.run_callback()
        else
            storm.os.wait_callback() -- go to sleep
        end
    end
end

cord.yield = function()
    coroutine.yield()
end

cord.cancel = function(handle)
    cord._cors[handle].k = true
end
