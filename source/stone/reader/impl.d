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
import stone.headers : AgnosticContainerHeader;
public import std.sumtype;

public import stone.headers : containerHeader, HeaderVersion;

import stone.headers.v1 : StoneContainerHeaderV1;
public import stone.reader.v1 : StoneReaderV1;
import std.exception : assumeUnique;

@safe:

/**
 * Possible errors when reading a stone archive
 */
public enum StoneReaderError
{
    /**
     * Invalid header (too short, etc)
     */
    badHeader,

    /**
     * Unsupported version
     */
    badVersion,

    /**
     * Magic in header didn't match supported stone values
     */
    badMagic,
}

/**
 * Result for .read
 */
public alias StoneReadResult = SumType!(StoneReaderV1, StoneReaderError);

@safe unittest
{
    /* mmap test */
    auto fpBased = stoneReader("test/bash-completion-2.11-1-1-x86_64.stone");
    assert(fpBased.data.length == 168864);

    /* cook in a file */
    static immutable builtin = () @trusted {
        return cast(ubyte[]) import("manifest.x86_64.bin");
    }();

    /* grab a reader for ubyte[] */
    auto spBased = stoneReader(builtin);
    assert(spBased.data.length == 394);

    /* Grab a reader for the stone file */
    fpBased.read.match!((scope ref StoneReaderV1 v1) {
        /* Should have a v1 reader! */
        v1.print();
    }, (err) {
        /* Catch all invalid stones */
        assert(0, "Invalid stone!");
    });
}

/**
 * Core reader type. Note, the Reader is required to support older archive
 * formats and operate in a general purpose access fashion.
 *
 * Params:
 *      Range = Range type
 */
package struct StoneReader(Range)
        if (isInputRange!Range && hasLength!Range && is(ElementType!Range : ubyte))
{
    Range data;
    AgnosticContainerHeader header;

    /**
     * Attempt to read the archive, and return the appropriate Reader type for it
     */
    StoneReadResult read() return @safe @nogc nothrow
    {
        /* Ensure we have a valid header first! */
        if (data.length > AgnosticContainerHeader.sizeof)
        {
            header = cast(AgnosticContainerHeader)(
                    cast(ubyte[32]) data[0 .. AgnosticContainerHeader.sizeof]);
        }
        else
        {
            return StoneReadResult(StoneReaderError.badHeader);
        }

        /* Magic matches us? */
        if (header.magic != containerHeader)
        {
            return StoneReadResult(StoneReaderError.badMagic);
        }

        /* Return the right version.. */
        switch (header.version_)
        {
        case HeaderVersion.v1:
            return StoneReadResult(StoneReaderV1(cast(StoneContainerHeaderV1) header, () @trusted {
                    return data[AgnosticContainerHeader.sizeof .. $].assumeUnique;
                }()));
        default:
            return StoneReadResult(StoneReaderError.badVersion);
        }
    }
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
