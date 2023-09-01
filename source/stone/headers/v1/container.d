/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.headers.v1.container
 *
 * Version 1 container headers for the stone format
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.headers.v1.container;

public import std.stdint : uint8_t, uint16_t, uint32_t;

import stone.headers : AgnosticContainerHeader, HeaderVersion, containerHeader;
import std.bitmanip : bigEndianToNative;

@safe:

@safe unittest
{
    auto hdr = cast(AgnosticContainerHeader) import("bash-completion-2.11-1-1-x86_64.stone");
    assert(hdr.magic == containerHeader);
    assert(hdr.version_ == HeaderVersion.v1);

    auto v1Hdr = cast(StoneContainerHeaderV1) hdr;
    assert(v1Hdr.payloads == 4);
    assert(v1Hdr.integrity == integrityCheck);
    assert(v1Hdr.type == FileType.binary);
}

/** 
 * Built-in integrity check, 21 randomish bytes in the header itself.
 * No match - no load.
 */
public const ubyte[21] integrityCheck = [
    0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0, 4, 0, 0, 5, 0, 0, 6, 0, 0, 7
];

/**
 * Describe the expected container content
 */
public enum FileType : uint8_t
{
    unknown = 0,
    binary = 1,
    delta = 2,
    repository = 3,
    buildManifest = 4,
}

/** 
 * Extend AgnosticContainerHeader for v1 with corruption check, payload count and type
 */
public struct StoneContainerHeaderV1
{
    /** 
     * 32-byte struct - interchangeable (lossless) with AgnosticContainerHeader
     */
    AgnosticContainerHeader hdr;
    alias hdr this;

    /** 
     * Returns: Number of payloads within this file
     */
    pragma(inline, true) pure @property uint16_t payloads() @safe @nogc nothrow
    {
        return bigEndianToNative!(uint16_t, uint16_t.sizeof)(data.payloads);
    }

    /** 
     * Returns: Integrity check (21-byte padding)
     */
    pragma(inline, true) pure @property ubyte[integrityCheck.length] integrity() @safe @nogc nothrow
    {
        return data.integrity;
    }

    /** 
     * Returns: The specified (1-byte) FileType
     */
    pragma(inline, true) pure @property FileType type() @safe @nogc nothrow
    {
        return data.type;
    }

private:
    pragma(inline, true) pure @property StoneContainerHeaderV1Data data() @safe @nogc nothrow
    {
        return hdr.data!StoneContainerHeaderV1Data;
    }
}

package struct StoneContainerHeaderV1Data
{
    ubyte[uint16_t.sizeof] payloads;
    ubyte[integrityCheck.length] integrity;
    FileType type;
}
