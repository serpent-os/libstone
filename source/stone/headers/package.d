/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.headers
 *
 * C representation of our fixed format headers
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.headers;

public import std.stdint : uint32_t;
import std.bitmanip : bigEndianToNative;

@safe:

public import stone.headers.v1;

/** 
 * We expect all stone container files to have this magic sequence in 
 */
const containerHeader = 0x006d6f73;

/** 
 * The header is initially read as an AgnosticContainerHeader, allowing
 * only two fields to be read: `version` and `magic`
 *
 * These fields are static for all time to ensure compatability in upgrade
 * paths, whilst allowing each format to specify how the remaining bytes of the
 * header should be used.
 *
 * Occupied memory:
 *
 *  [0   .. 4] = uint32_t [magic (4b)]
 *  [$-4 .. $] = uint32_t [version (4b)]
 */
public struct AgnosticContainerHeader
{
    /** 
     * Raw data for this header.
     */
    ubyte[32] rawHeader;
    alias rawHeader this;

    /** 
     * Returns: the version identifer as an integer (stored: BE)
     */
    pragma(inline, true) pure uint32_t version_() @safe @nogc nothrow
    {
        ubyte[uint32_t.sizeof] byteSection = rawHeader[$ - uint32_t.sizeof .. $];
        return bigEndianToNative!(uint32_t, uint32_t.sizeof)(byteSection);
    }

    /** 
     * Returns: Magic identifier for the container header (stored: BE)
     */
    pragma(inline, true) pure uint32_t magic() @safe @nogc nothrow
    {
        ubyte[uint32_t.sizeof] byteSection = rawHeader[0 .. uint32_t.sizeof];
        return bigEndianToNative!(uint32_t, uint32_t.sizeof)(byteSection);
    }
}
