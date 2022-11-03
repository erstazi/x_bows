import fetch from 'node-fetch'
import yargs from 'yargs/yargs'
import {hideBin} from 'yargs/helpers'

const argv = yargs(hideBin(process.argv)).argv

try {
    const body = {
        method: 'git',
        title: argv.title,
        ref: 'master'
    }

    const response = await fetch('https://content.minetest.net/api/packages/SaKeL/x_bows/releases/new/', {
        method: 'POST',
        body: JSON.stringify(body),
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${argv.token}`
        }
    })
    const data = await response.json()

    console.log(data)

    if (!data.succes) {
        process.exit(1)
    }
} catch (error) {
    console.log(error)
    process.exit(1)
}
