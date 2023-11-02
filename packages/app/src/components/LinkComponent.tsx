import React, { ReactNode } from 'react'
import Link from 'next/link'

interface Props {
    href: string
    children: ReactNode
    isExternal?: boolean
    className?: string
}

export function LinkComponent({ href, children, isExternal, className }: Props) {
    const isExternalLink = href.match(/^([a-z0-9]*:|.{0})\/\/.*$/) || isExternal

    if (isExternalLink) {
        return (
            <Link className={className} href={href} target="_blank" rel="noopener noreferrer">
                {children}
            </Link>
        )
    }

    return (
        <Link className={className} href={href}>
            {children}
        </Link>
    )
}

LinkComponent.defaultProps = {
    isExternal: false,
    className: '',
}

export default LinkComponent
