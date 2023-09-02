/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.reader.v1
 *
 * APIs to read v1 stone archive files
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.reader.v1;

import stone.headers.v1;

/** 
 * V1 specific payload reader
 */
package(stone.reader) struct StoneReaderV1
{
    StoneContainerHeaderV1 header;

    /* Remaining data */
    immutable(ubyte[]) data;

    void print() @trusted scope
    {
        imported!"core.stdc.stdio".printf("I have %d payloads\n", header.payloads);
    }
}
