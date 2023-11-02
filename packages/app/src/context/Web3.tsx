'use client'

import React, { PropsWithChildren, useEffect, useState } from 'react'
import { createWeb3Modal, defaultWagmiConfig } from '@web3modal/wagmi/react'
import { configureChains, WagmiConfig } from 'wagmi'
import { publicProvider } from 'wagmi/providers/public'

import { ETH_CHAINS } from '../utils/network'
import { SITE_DESCRIPTION, SITE_NAME, SITE_URL } from '../utils/site'

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? ''
if (!projectId) {
    // eslint-disable-next-line no-console
    console.error('You need to provide a NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID env variable')
}
const { chains } = configureChains(ETH_CHAINS, [publicProvider()])

const metadata = {
    name: SITE_NAME,
    description: SITE_DESCRIPTION,
    url: SITE_URL,
    icons: [],
}
const wagmiConfig = defaultWagmiConfig({ chains, projectId, metadata })

createWeb3Modal({ wagmiConfig, projectId, chains })

export function Web3Provider({ children }: PropsWithChildren) {
    const [ready, setReady] = useState(false)

    useEffect(() => {
        setReady(true)
    }, [])

    return ready && <WagmiConfig config={wagmiConfig}>{children}</WagmiConfig>
}

export default Web3Provider
