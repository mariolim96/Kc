import React from 'react'

import Connect from '../molecules/Connect'
import ThemeToggler from '../ui/theme-toggler'

const Header = () => {
    return (
        <nav className=" flex justify-end gap-8">
            <ThemeToggler />
            <Connect />
        </nav>
    )
}

export default Header
