import React from 'react'

import { SITE_NAME } from '../utils/site'
import Connect from './Connect'
import { LinkComponent } from './LinkComponent'

function Header() {
    return (
        <header className="navbar flex justify-between p-4 pt-0">
            <LinkComponent href="/">
                <h1 className="text-lg font-bold ">{SITE_NAME}</h1>
            </LinkComponent>

            <Connect />
        </header>
    )
}

export default Header
