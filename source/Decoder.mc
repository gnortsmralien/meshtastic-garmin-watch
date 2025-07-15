// Decoder.mc
//
// Deserializes a ByteArray into a Dictionary representation of a protobuf message.
// It uses a schema dictionary to map field tags back to their symbolic names.

using Toybox.Lang;
using Toybox.System;

module ProtoBuf {
    class Decoder {
        private var _buffer;
        private var _index;

        // Constructor
        public function initialize() {
            _buffer = null;
            _index = 0;
        }

        // Main public method to decode a byte array.
        // @param bytes The ByteArray containing the serialized message.
        // @param schema The Dictionary describing the message structure.
        // @return The deserialized message as a Dictionary.
        public function decode(bytes as Lang.ByteArray, schema as Lang.Dictionary) as Lang.Dictionary {
            _buffer = bytes;
            _index = 0;
            var message = {};

            // Invert the schema for fast lookup from tag number to symbol
            var tagMap = {};
            var keys = schema.keys();
            for (var i = 0; i < keys.size(); i++) {
                var sym = keys[i];
                var fieldInfo = schema[sym];
                tagMap[fieldInfo[:tag]] = { :symbol => sym, :schema => fieldInfo };
            }

            while (_index < _buffer.size()) {
                var tagVal = readVarint();
                var wireType = tagVal & 0x07;
                var fieldNumber = tagVal >> 3;

                if (tagMap.hasKey(fieldNumber)) {
                    var fieldInfo = tagMap[fieldNumber];
                    var fieldSymbol = fieldInfo[:symbol];
                    var fieldSchema = fieldInfo[:schema];
                    var value = null;

                    switch (wireType) {
                        case WIRETYPE_VARINT:
                            value = readVarint();
                            break;
                        case WIRETYPE_FIXED32:
                            value = readFixed32();
                            break;
                        case WIRETYPE_FIXED64:
                            value = readFixed64();
                            break;
                        case WIRETYPE_LEN:
                            var len = readVarint().toNumber();
                            var payloadBytes = _buffer.slice(_index, _index + len);
                            _index += len;
                            // Check if it's an embedded message
                            if (fieldSchema.hasKey(:schema)) {
                                var subDecoder = new Decoder();
                                value = subDecoder.decode(payloadBytes, fieldSchema[:schema]);
                            } else {
                                // Assume bytes, let application convert to string if needed
                                value = payloadBytes;
                            }
                            break;
                        default:
                            // Unknown wire type, skip it
                            skipField(wireType.toNumber());
                            break;
                    }
                    if (value != null) {
                        message[fieldSymbol] = value;
                    }
                } else {
                    // Unknown field, skip it
                    System.println("Skipping unknown field: " + fieldNumber);
                    skipField(wireType.toNumber());
                }
            }

            return message;
        }

        // Skips a field based on its wire type. Essential for forward compatibility.
        private function skipField(wireType as Lang.Number) {
            switch (wireType) {
                case WIRETYPE_VARINT:
                    readVarint(); // Read and discard
                    break;
                case WIRETYPE_FIXED64:
                    _index += 8;
                    break;
                case WIRETYPE_LEN:
                    var len = readVarint().toNumber();
                    _index += len;
                    break;
                case WIRETYPE_FIXED32:
                    _index += 4;
                    break;
            }
        }

        // Reads a Varint-encoded number from the buffer.
        private function readVarint() as Lang.Long {
            var result = 0L;
            var shift = 0;
            while (true) {
                var byte = _buffer[_index];
                _index++;
                result |= ((byte & 0x7F).toLong() << shift);
                if ((byte & 0x80) == 0) {
                    return result;
                }
                shift += 7;
                if (shift >= 64) {
                    // Should not happen with valid data
                    System.println("Error: Malformed Varint");
                    return -1L;
                }
            }
            return -1L; // Should be unreachable
        }
        
        // Reads a 32-bit little-endian number.
        private function readFixed32() as Lang.Number {
            var b1 = _buffer[_index].toLong();
            var b2 = _buffer[_index+1].toLong();
            var b3 = _buffer[_index+2].toLong();
            var b4 = _buffer[_index+3].toLong();
            _index += 4;
            var result = (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
            // Handle signed conversion if needed by application
            return result.toNumber();
        }

        // Reads a 64-bit little-endian number.
        private function readFixed64() as Lang.Long {
            var val = 0L;
            for (var i = 0; i < 8; i++) {
                val |= (_buffer[_index + i].toLong() << (i * 8));
            }
            _index += 8;
            return val;
        }
    }
}