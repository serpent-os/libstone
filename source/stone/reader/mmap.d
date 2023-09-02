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
    assert(nonExistent == null);

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
    alias data this;
    ubyte[] data;

    @disable this();
    @disable this(this);

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

        data = cast(ubyte[])(dataPage[0 .. fileSize]);
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
