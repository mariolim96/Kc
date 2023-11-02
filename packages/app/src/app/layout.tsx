import React, { PropsWithChildren } from 'react'
import type { Metadata } from 'next'

import { Layout } from '../components/Layout'
import Providers from '../context/Providers'
import { SITE_DESCRIPTION, SITE_NAME } from '../utils/site'

import '../assets/globals.css'

export const metadata: Metadata = {
    title: SITE_NAME,
    description: SITE_DESCRIPTION,
}

export default function RootLayout({ children }: PropsWithChildren) {
    return (
        <html lang="en">
            <body>
                <Providers>
                    <Layout>{children}</Layout>
                </Providers>
            </body>
        </html>
    )
}
