/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.headers.v1.payload
 *
 * Payload headers per v1 of the moss .stone format
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.headers.v1.payload;

public import std.stdint : uint8_t, uint16_t, uint32_t, uint64_t;
import std.bitmanip : bigEndianToNative;

@safe:

@safe unittest
{
    static hdrData = cast(ubyte[32]) import("bash-completion-2.11-1-1-x86_64.stone")[32 .. 64];
    auto hdr = cast(StonePayloadHeaderV1) hdrData;
    assert(hdr.type == PayloadType.meta);
    assert(hdr.version_ == 1);
    assert(hdr.compression == CompressionType.zstd);
}

/**
 * Currently we just support zstd payload compression
 */
public enum CompressionType : uint8_t
{
    unknown = 0,
    none = 1,
    zstd = 2,
}

/**
 * All payloads are identified by a specific type tag,
 * to permit restoring the data via the appropriate codepaths
 */
public enum PayloadType : uint8_t
{
    unknown = 0,
    meta = 1,
    content = 2,
    layout = 3,
    index = 4,
    attributes = 5,
    dumb = 6
}

/**
 * The v1 payload header contains a number of BE encoded fields
 * defining the size and record count characteristics, as well as
 * the version stamp and type for deserialisation purposes.
 *
 * Additionally all payloads include a built-in checksum to prevent
 * corrupted reads
 */
public struct StonePayloadHeaderV1
{
    StonePayloadHeaderV1Data data;
    alias data this;

    /**
     * Returns: Payload version in use
     */
    pragma(inline, true) pure @property uint16_t version_() @safe @nogc nothrow
    {
        return bigEndianToNative!(uint16_t, uint16_t.sizeof)(data.version__);
    }

    /**
     * Returns: Type of the payload
     */
    pragma(inline, true) pure @property PayloadType type() @safe @nogc nothrow
    {
        return data.type_;
    }

    /**
     * Returns: Compression algorithm used for payload blob
     */
    pragma(inline, true) pure @property CompressionType compression() @safe @nogc nothrow
    {
        return data.compression_;
    }
}

package struct StonePayloadHeaderV1Data
{
    // Real Size
    ubyte[uint64_t.sizeof] size_;

    // Decompressed size
    ubyte[uint64_t.sizeof] xsize_;

    // Checksum (XXHash3!64)
    ubyte[8] checksum_;

    // Number of records contained in the payload
    ubyte[uint32_t.sizeof] records_;

    // Version of the payload per *type*
    ubyte[uint16_t.sizeof] version__;

    // Type of the payload
    PayloadType type_;

    // And finally, the compression algorithm used.
    CompressionType compression_;
}

static assert(StonePayloadHeaderV1Data.sizeof == 32u);
