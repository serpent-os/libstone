/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.reader.mmap
 *
 * Make mmap() nice to use from D for reading a file.
 * TODO: Add error handling!
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.reader.mmap;

@safe:

import core.sys.posix.fcntl : open, O_RDONLY, O_CLOEXEC;
import core.sys.posix.unistd : close;
import core.sys.posix.sys.mman;
import core.sys.posix.sys.stat;

@safe unittest
{
    auto nonExistent = mappedFile("REAMDE.notmd");
    auto data = nonExistent[0 .. 32];
    assert(data == null);

    /* Check README header matches expectations */
    auto doExist = mappedFile("README.md");
    static immutable cmp = ['#', ' ', 'l', 'i', 'b', 's', 't', 'o', 'n', 'e'];
    assert(doExist[0 .. cmp.length] == cmp);
}

/** 
 * Map a file and make it usable as a D ubyte[] range
 */
public struct MappedFile
{
    @disable this();
    @disable this(this);

    /** 
     * Slice the mapped file
     *
     * Params:
     *   start = Start of the requested slice
     *   end = End of the requested slice
     * Returns: a ubyte[] slice for the given input
     */
    auto opSlice(size_t start, size_t end) @nogc nothrow
    {
        if (start > end || end > fileSize || fileSize == 0)
            return null;

        return () @trusted { return cast(ubyte[])(dataPage[start .. end]); }();
    }

    ubyte[] opSlice() @nogc nothrow
    {
        if (fileSize == 0)
            return null;
        return () @trusted { return cast(ubyte[])(dataPage[0 .. fileSize]); }();
    }

    /** 
     * Returns: Length of the mapped file
     */
    auto opDollar() @nogc nothrow => fileSize;
    alias length = opDollar;

    ~this() @trusted nothrow @nogc
    {
        if (fd <= 0)
            return;
        dataPage.munmap(fileSize);
        fd.close;
        fd = 0;
    }

private:

    /** 
     * Construct a new MappedFile
     * Params:
     *   path = Filepath to open
     */
    this(const char* path) @trusted nothrow @nogc
    {
        fd = path.open(O_RDONLY | O_CLOEXEC);
        if (fd < 0)
            return;

        stat_t result;
        if (path.stat(&result) != 0)
            return;
        fileSize = result.st_size;
        dataPage = mmap(null, result.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (dataPage is null)
            return;
    }

    /* Underlying file descriptor */
    int fd = -1;
    void* dataPage;
    size_t fileSize;
}

/** 
 * Attempt to map a file to a kernel-side buffer
 *
 * Params:
 *   path = Filesystem path to verify
 * Returns: A MappedFile with no-copy semantics
 */
auto mappedFile(const char* path) => MappedFile(path);
