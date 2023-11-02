import React, { PropsWithChildren } from 'react'

import { Footer } from './Footer'
import Header from './Header'

export function Layout({ children }: PropsWithChildren) {
    return (
        <div className="flex min-h-screen flex-col">
            <Header />

            <main className="container mx-auto max-w-3xl grow px-4">{children}</main>
            <Footer />
        </div>
    )
}
export default Layout
