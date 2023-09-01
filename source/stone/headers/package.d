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
import std.bitmanip : bigEndianToNative, nativeToBigEndian;

@safe @nogc nothrow:

public import stone.headers.v1;

/** 
 * We expect all stone container files to have this magic sequence in 
 */
const containerHeader = 0x006d6f73;

/**
 * Version of the header format
 */
public enum HeaderVersion : uint32_t
{
    v1 = 1,
}

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
     * Returns: the version identifer as an integer (stored: BE)
     */
    pragma(inline, true) pure @property HeaderVersion version_()
    {
        return bigEndianToNative!(HeaderVersion, HeaderVersion.sizeof)(version__);
    }

    /** 
     * Update the version property
     *
     * Params:
     *   newVersion = Version to set within the payload
     */
    pragma(inline, true) pure @property void version_(HeaderVersion newVersion)
    {
        version__ = nativeToBigEndian(newVersion);
    }

    /** 
     * Returns: Magic identifier for the container header (stored: BE)
     */
    pragma(inline, true) pure @property uint32_t magic()
    {
        return bigEndianToNative!(uint32_t, uint32_t.sizeof)(magic_);
    }

    /** 
     * Update the magic property
     *
     * Params:
     *   newMagic = New magic setting
     */
    pragma(inline, true) pure @property void magic(uint32_t newMagic)
    {
        magic_ = nativeToBigEndian(newMagic);
    }

package:
    pragma(inline, true) pure @property T data(T)()
            if (T.sizeof == 24 && __traits(isPOD, T))
    {
        return cast(T) data_;
    }

private:
    AgnosticContainerHeaderPayload payload;
    alias payload this;
}

package struct AgnosticContainerHeaderPayload
{
    ubyte[4] magic_;
    ubyte[24] data_;
    ubyte[4] version__;
}
