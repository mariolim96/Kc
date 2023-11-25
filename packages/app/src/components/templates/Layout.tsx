'use client'

import React from 'react'

import Navbar from '../organism/Header'
import Sidebar from '../organism/sidebar'

interface Props {
    children: JSX.Element
}
export const Layout = ({ children }: Props) => (
    <div className="flex h-screen overflow-hidden">
        <Sidebar />
        <div className="w-full h-screen flex-col justify-end pt-8 pb-8">
            <Navbar />
            <div className="h-full overflow-y-auto ">
                <div className="mx-4 my-4 flex flex-col gap-4 ">{children}</div>
            </div>
        </div>
    </div>
)

export default Layout
// h-screen overflow-y-scroll
