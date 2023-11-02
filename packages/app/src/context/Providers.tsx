'use client'

import React, { PropsWithChildren } from 'react'
import { useIsMounted } from 'hooks/index'

import { ThemeProvider } from './ThemeProvider'
import { Web3Provider } from './Web3'

function Providers({ children }: PropsWithChildren) {
    const isMounted = useIsMounted()
    return (
        isMounted && (
            <Web3Provider>
                <ThemeProvider>{children}</ThemeProvider>
            </Web3Provider>
        )
    )
}

export default Providers
