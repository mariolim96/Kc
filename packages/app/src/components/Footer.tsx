import React from 'react'
import { FaGithub, FaTwitter } from 'react-icons/fa6'

import { SITE_DESCRIPTION, SOCIAL_GITHUB, SOCIAL_TWITTER } from '../utils/site'
import { LinkComponent } from './LinkComponent'
import { NetworkStatus } from './NetworkStatus'

export function Footer() {
    return (
        <>
            <div className="place-self-end">
                <NetworkStatus />
            </div>

            <footer className="text-neutral-content footer bg-neutral text-neutral-content footer sticky top-[100vh] flex items-center justify-between p-4">
                <p>{SITE_DESCRIPTION}</p>
                <div className="flex gap-4">
                    <LinkComponent href={`https://github.com/${SOCIAL_GITHUB}`}>
                        <FaGithub />
                    </LinkComponent>
                    <LinkComponent href={`https://twitter.com/${SOCIAL_TWITTER}`}>
                        <FaTwitter />
                    </LinkComponent>
                </div>
            </footer>
        </>
    )
}

export default Footer
