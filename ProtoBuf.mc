// ProtoBuf.mc
//
// Core module for the Monkey C Protocol Buffers library.
// Contains shared constants, Meshtastic-specific message schemas,
// and utility functions for handling the Meshtastic streaming protocol.

using Toybox.Lang;
using Toybox.System;

module ProtoBuf {

    // Protobuf wire type constants, as per the official specification.
    // See: https://protobuf.dev/programming-guides/encoding/#structure
    enum {
        WIRETYPE_VARINT = 0,
        WIRETYPE_FIXED64 = 1,
        WIRETYPE_LEN = 2,
        // WIRETYPE_START_GROUP = 3, // Deprecated
        // WIRETYPE_END_GROUP = 4,   // Deprecated
        WIRETYPE_FIXED32 = 5
    }

    // Meshtastic Streaming Protocol constants.
    const START1 = 0x94;
    const START2 = 0xc3;

    // --- Meshtastic Schema Definitions ---
    // These dictionaries define the structure of Meshtastic protobuf messages.
    // They map field symbols to their tag number and type information, which is
    // used by the Encoder and Decoder.

    // Schema for meshtastic.Data
    // This is the payload for most application-level messages.
    const SCHEMA_DATA = {
        :portnum => { :tag => 1, :type => WIRETYPE_VARINT },
        :payload => { :tag => 2, :type => WIRETYPE_LEN }, // bytes
        :want_response => { :tag => 3, :type => WIRETYPE_VARINT }, // bool
        :dest => { :tag => 4, :type => WIRETYPE_VARINT }, // uint32
        :source => { :tag => 5, :type => WIRETYPE_VARINT }, // uint32
        :request_id => { :tag => 6, :type => WIRETYPE_VARINT }, // uint32
        :reply_id => { :tag => 7, :type => WIRETYPE_VARINT }, // uint32
    };

    // Schema for meshtastic.MeshPacket
    // This is the outer envelope for packets sent over the mesh.
    const SCHEMA_MESHPACKET = {
        :from => { :tag => 1, :type => WIRETYPE_VARINT }, // uint32
        :to => { :tag => 2, :type => WIRETYPE_VARINT }, // uint32
        :channel => { :tag => 3, :type => WIRETYPE_VARINT }, // uint32
        :decoded => { :tag => 4, :type => WIRETYPE_LEN, :schema => SCHEMA_DATA }, // Embedded Data message
        :id => { :tag => 5, :type => WIRETYPE_VARINT }, // uint32
        :rx_time => { :tag => 6, :type => WIRETYPE_VARINT }, // fixed32
        :rx_snr => { :tag => 7, :type => WIRETYPE_FIXED32 }, // float
        :hop_limit => { :tag => 8, :type => WIRETYPE_VARINT }, // uint32
        :want_ack => { :tag => 9, :type => WIRETYPE_VARINT }, // bool
        :priority => { :tag => 10, :type => WIRETYPE_VARINT } // enum
    };

    // Schema for meshtastic.Position
    const SCHEMA_POSITION = {
        :latitude_i => { :tag => 1, :type => WIRETYPE_FIXED32 }, // sfixed32
        :longitude_i => { :tag => 2, :type => WIRETYPE_FIXED32 }, // sfixed32
        :altitude => { :tag => 3, :type => WIRETYPE_VARINT }, // int32
        :time => { :tag => 4, :type => WIRETYPE_VARINT }, // fixed32 (epoch time)
        :sats_in_view => { :tag => 19, :type => WIRETYPE_VARINT }, // uint32
        // Other position fields can be added here as needed
    };

    // Wraps a protobuf payload with the Meshtastic streaming protocol header.
    // @param protoBytes The serialized protobuf payload.
    // @return A new ByteArray containing the full stream packet.
    public function wrap(protoBytes as ByteArray) as ByteArray {
        var len = protoBytes.size();
        if (len > 0xFFFF) {
            System.println("Error: Protobuf payload too large for streaming protocol.");
            return null;
        }

        var header = new [4]b;
        header[0] = START1;
        header[1] = START2;
        header[2] = (len >> 8) & 0xFF; // MSB of length
        header[3] = len & 0xFF;        // LSB of length

        return header.addAll(protoBytes);
    }

    // Unwraps a Meshtastic streaming protocol packet to extract the protobuf payload.
    // This is a simplified implementation that assumes the buffer starts with a valid packet.
    // A full implementation would scan the buffer for START1/START2.
    // @param streamBytes The raw bytes from the stream.
    // @return The extracted protobuf payload as a ByteArray, or null if invalid.
    public function unwrap(streamBytes as ByteArray) as ByteArray {
        if (streamBytes == null || streamBytes.size() < 4) {
            return null; // Not enough data for a header
        }

        if (streamBytes[0] != START1 || streamBytes[1] != START2) {
            System.println("Error: Invalid Meshtastic stream header.");
            return null;
        }

        var len = (streamBytes[2] << 8) | streamBytes[3];
        if (streamBytes.size() < 4 + len) {
            System.println("Error: Incomplete packet. Expected " + len + " bytes, got " + (streamBytes.size() - 4));
            return null;
        }

        return streamBytes.slice(4, 4 + len);
    }
}