/**
 * Run LUA diagnostics in continuous integration
 * Copyright (C) 2023 SaKeL <juraj.vajda@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to juraj.vajda@gmail.com
 */

import * as path from 'node:path'
import * as fs from 'node:fs'
import {exec} from 'node:child_process'
import yargs from 'yargs/yargs'
import {hideBin} from 'yargs/helpers'
import jaguar from 'jaguar'

const argv = yargs(hideBin(process.argv)).argv
const cwd = process.cwd()
const logPath = path.join(cwd, 'logs')

// Extract lua language server
const from = path.join(cwd, 'bin/lua-language-server-3.5.6-linux-x64.tar.gz');
const to = path.join(cwd, 'bin', 'lua-language-server-3.5.6-linux-x64');
const extract = jaguar.extract(from, to)

// extract.on('file', (name) => {
//     console.log(name)
// })

extract.on('start', () => {
    console.log('Extracting...')
})

// extract.on('progress', (percent) => {
//     console.log(percent + '%')
// })

extract.on('error', (error) => {
    console.error(error)
    process.exit(1)
})

extract.on('end', () => {
    console.log('Extracting: Done')

    // Delete directory recursively
    try {
        fs.rmSync(logPath, { recursive: true, force: true })
        console.log(`Removed folder: ${logPath}`)
    } catch (err) {
        console.error(`Error while deleting ${logPath}.`)
        console.error(err)
    }

    let command = './bin/lua-language-server-3.5.6-linux-x64/bin/lua-language-server'

    if (argv.local) {
        command = 'lua-language-server'
    }

    exec(`${command}  --logpath "${logPath}" --check "${cwd}"`, (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`)
            process.exit(1)
        }

        if (stderr) {
            console.log(`stderr: ${stderr}`)
            process.exit(1)
        }

        console.log(`\n${stdout}`)

        if (fs.existsSync('./logs/check.json')) {
            const rawdata = fs.readFileSync('./logs/check.json')
            const diagnosticsJson = JSON.parse(rawdata)

            Object.keys(diagnosticsJson).forEach((key) => {
                console.log(key)

                diagnosticsJson[key].forEach((errObj) => {
                    console.log(`line: ${errObj.range.start.line} - ${errObj.message}`)
                })
            })

            console.error('Fix the errors/warnings above.')
            process.exit(1)
        }

        // Delete directory recursively
        const llsFolder = path.join(cwd, 'bin', 'lua-language-server-3.5.6-linux-x64')

        try {
            fs.rmSync(llsFolder, { recursive: true, force: true })
            console.log(`Removed folder: ${llsFolder}`)
        } catch (err) {
            console.error(`Error while deleting ${llsFolder}.`)
            console.error(err)
            process.exit(1)
        }
    })
})
