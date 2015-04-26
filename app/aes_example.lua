sh = require "stormsh"
sh.start()


-- First you need to set your key for AES encryption or decryption
-- The key is a 32 byte binary safe string (256 bit)
storm.aes.setkey("abcdabcdabcdabcdabcdabcdabcdabcd")

-- Then you can encrypt or decrypt. The operation requires an
-- Initialisation Vector, or IV. There are lots of ways of
-- getting this. It's not a secret, so you can send it in
-- plain text with the message. One method is simply to use
-- an incrementing number for each message. The only constraint
-- is that you SHOULD not use the same IV twice, as it allows for
-- key discovery. Read up on AES a bit.
-- The actual message itself needs to have a length that is an
-- exact multiple of 16. You will need to pad it so that works.
initialisation_vector = "0123456789123456"
message = "ABCDabcd0123WXYZ"
encrypted_string = storm.aes.encrypt(initialisation_vector, message)

-- To decrypt, just use the save IV, and the encrypted message
dec_message = storm.aes.decrypt(initialisation_vector, encrypted_string)

print ("Got", dec_message, " expected ",message)

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()