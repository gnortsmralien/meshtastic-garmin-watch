// Encoder.mc
//
// Serializes a Dictionary representation of a protobuf message into a ByteArray.
// It uses a schema dictionary to determine the tag and type for each field.

using Toybox.Lang;
using Toybox.System;

module ProtoBuf {
    class Encoder {
        private var _buffer;

        // Constructor
        public function initialize() {
            _buffer = new [0]b;
        }

        // Main public method to encode a message.
        // @param message The Dictionary containing the message data.
        // @param schema The Dictionary describing the message structure.
        // @return The serialized message as a ByteArray.
        public function encode(message as Lang.Dictionary, schema as Lang.Dictionary) as Lang.ByteArray {
            _buffer = new [0]b;
            var keys = schema.keys();

            for (var i = 0; i < keys.size(); i++) {
                var fieldSymbol = keys[i];
                if (message.hasKey(fieldSymbol)) {
                    var value = message[fieldSymbol];
                    var fieldSchema = schema[fieldSymbol];
                    encodeField(fieldSchema, value);
                }
            }
            return _buffer;
        }

        // Encodes a single field based on its schema definition.
        private function encodeField(fieldSchema as Lang.Dictionary, value) {
            var type = fieldSchema[:type];
            var tag = fieldSchema[:tag];

            switch (type) {
                case WIRETYPE_VARINT:
                    // Handles int32, uint32, bool, enum, sint32, sint64
                    // Note: sint is handled by ZigZag encoding before calling this.
                    // For simplicity, we assume values are Numbers or Booleans.
                    var numValue = 0;
                    if (value instanceof Lang.Boolean) {
                        numValue = value ? 1 : 0;
                    } else {
                        numValue = value as Lang.Number;
                    }
                    writeTag(tag, WIRETYPE_VARINT);
                    writeVarint(numValue);
                    break;

                case WIRETYPE_FIXED32:
                    // Handles float, fixed32, sfixed32
                    writeTag(tag, WIRETYPE_FIXED32);
                    writeFixed32(value);
                    break;
                
                case WIRETYPE_FIXED64:
                    // Handles double, fixed64, sfixed64
                    writeTag(tag, WIRETYPE_FIXED64);
                    writeFixed64(value);
                    break;

                case WIRETYPE_LEN:
                    // Handles string, bytes, embedded messages
                    writeTag(tag, WIRETYPE_LEN);
                    if (value instanceof Lang.String) {
                        var bytes = stringToBytes(value);
                        writeVarint(bytes.size());
                        _buffer = _buffer.addAll(bytes);
                    } else if (value instanceof Lang.ByteArray) {
                        writeVarint(value.size());
                        _buffer = _buffer.addAll(value);
                    } else if (value instanceof Lang.Dictionary) {
                        // Embedded message
                        var subEncoder = new Encoder();
                        var subBytes = subEncoder.encode(value, fieldSchema[:schema]);
                        writeVarint(subBytes.size());
                        _buffer = _buffer.addAll(subBytes);
                    }
                    break;
            }
        }

        // Writes a tag (field number + wire type) to the buffer.
        private function writeTag(fieldNumber as Lang.Number, wireType as Lang.Number) {
            var tag = (fieldNumber << 3) | wireType;
            writeVarint(tag);
        }

        // Encodes a number as a Varint and writes it to the buffer.
        // Handles up to 32-bit unsigned integers for Monkey C's Number type.
        private function writeVarint(value as Lang.Number) {
            var val = value.toLong(); // Use Long for bitwise operations
            while (true) {
                if ((val & ~0x7F) == 0) {
                    _buffer = _buffer.add(val.toNumber());
                    break;
                } else {
                    _buffer = _buffer.add(((val & 0x7F) | 0x80).toNumber());
                    val = val >> 7;
                }
            }
        }

        // Writes a 32-bit fixed-width number (little-endian).
        private function writeFixed32(value) {
            var bytes = new [4]b;
            // Toybox.Lang.ByteArray.encodeNumber is not available, so we do it manually.
            // Or if available, it can be used for simplification. Assuming manual for broader compatibility.
            var longVal = 0L;
            if (value instanceof Lang.Float) {
                // NOTE: Monkey C does not provide a direct way to get the IEEE 754 bits of a float.
                // This is a major limitation. For testing, we can use pre-computed byte arrays.
                // For a real application, a native C extension or a different approach would be needed.
                // Here, we'll handle it as an integer for demonstration.
                longVal = value.toLong();
            } else {
                longVal = value.toLong();
            }

            bytes[0] = (longVal & 0xFF).toNumber();
            bytes[1] = ((longVal >> 8) & 0xFF).toNumber();
            bytes[2] = ((longVal >> 16) & 0xFF).toNumber();
            bytes[3] = ((longVal >> 24) & 0xFF).toNumber();
            _buffer = _buffer.addAll(bytes);
        }

        // Writes a 64-bit fixed-width number (little-endian).
        private function writeFixed64(value as Lang.Long) {
             var bytes = new [8]b;
             // Similar limitation as writeFixed32 for doubles.
             bytes[0] = (value & 0xFF).toNumber();
             bytes[1] = ((value >> 8) & 0xFF).toNumber();
             bytes[2] = ((value >> 16) & 0xFF).toNumber();
             bytes[3] = ((value >> 24) & 0xFF).toNumber();
             bytes[4] = ((value >> 32) & 0xFF).toNumber();
             bytes[5] = ((value >> 40) & 0xFF).toNumber();
             bytes[6] = ((value >> 48) & 0xFF).toNumber();
             bytes[7] = ((value >> 56) & 0xFF).toNumber();
             _buffer = _buffer.addAll(bytes);
        }

        // Helper to convert a string to a UTF-8 byte array.
        // Monkey C strings are internally UTF-8, but toByteArray() might not be available
        // on all API levels. A robust implementation would handle this carefully.
        private function stringToBytes(str as Lang.String) as Lang.ByteArray {
            // This is a simplification. Real UTF-8 conversion is more complex if non-ASCII
            // characters are involved and no built-in method is available.
            var bytes = new [str.length()]b;
            for (var i = 0; i < str.length(); i++) {
                bytes[i] = str.toCharArray()[i].toNumber();
            }
            return bytes;
        }
    }
}