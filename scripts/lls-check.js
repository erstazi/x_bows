import * as path from 'node:path'
import * as fs from 'node:fs'
import {exec} from 'node:child_process'
import yargs from 'yargs/yargs'
import {hideBin} from 'yargs/helpers'

const argv = yargs(hideBin(process.argv)).argv

const logPath = path.join(process.cwd(), 'logs')
const checkPath = process.cwd()
let command = './bin/lua-language-server-3.5.6-linux-x64/bin/lua-language-server'

if (argv.local) {
    command = 'lua-language-server'
}

exec(`${command}  --logpath "${logPath}" --check "${checkPath}"`, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`)
        return
    }

    if (stderr) {
        console.log(`stderr: ${stderr}`)
        return
    }

    const rawdata = fs.readFileSync('./logs/check.json')
    const diagnosticsJson = JSON.parse(rawdata)

    Object.keys(diagnosticsJson).forEach((key) => {
        console.log(key)

        diagnosticsJson[key].forEach((errObj) => {
            console.log(`line: ${errObj.range.start.line} - ${errObj.message}`)
        })
    })

    console.log(`stdout: ${stdout}`)

    if (Object.keys(diagnosticsJson).length) {
        console.error('Fix the errors/warnings above.')
        process.exit(1)
    }
})
