/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.reader.impl;
 *
 * APIs to read stone archive files
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.reader.impl;

import std.range : ElementType, isInputRange, hasLength;

@safe:

@safe unittest
{
    /* mmap test */
    auto fpBased = stoneReader("test/manifest.x86_64.bin");
    assert(fpBased.data.length == 394);

    /* cook in a file */
    static immutable builtin = () @trusted {
        return cast(ubyte[]) import("manifest.x86_64.bin");
    }();

    /* grab a reader for ubyte[] */
    auto spBased = stoneReader(builtin);
    assert(spBased.data.length == 394);
}

/**
 * Core reader type. Note, the Reader is required to support older archive
 * formats and operate in a general purpose access fashion.
 *
 * Params:
 *      Range = Range type
 *      isRC = Set to true for `.borrow` semantics
 */
package struct StoneReader(Range)
        if (isInputRange!Range && hasLength!Range && is(ElementType!Range : ubyte))
{
    Range data;
}

/**
 * Return a StoneReader for the given input path
 * Note: This is automatically wrapped into an mmap reader
 */
auto stoneReader(const char* path)
{
    import stone.reader.mmap : mappedFile, MappedFile;

    static struct MappedReader
    {
        MappedFile mf;
        StoneReader!(ubyte[]) parent;
        alias parent this;

        @disable this(this);
        @disable this();

        this(const char* path) @trusted
        {
            this.mf = mappedFile(path);
            this.data = mf[];
        }
    }

    return MappedReader(path);
}

/**
 * Construct a new StoneReader for the given input range
 * Note: The range must be a ubyte[] slice with a known length.
 */
auto stoneReader(Range)(Range input) => StoneReader!Range(input);
