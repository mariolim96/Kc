import React from 'react'

import { Button } from '../components/ui/button'
import { Toggle } from '../components/ui/toggle'
import { SITE_DESCRIPTION } from '../utils/site'

export default function Home() {
    return (
        <>
            <p>{SITE_DESCRIPTION}</p>
            <Button>Click me</Button>
            <Toggle>Maura e scema</Toggle>
        </>
    )
}
