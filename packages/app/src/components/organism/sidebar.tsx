'use client'

import React from 'react'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import cn from '@/utils/utils'
import { BsBoxArrowInDown } from 'react-icons/bs'
import { CgArrowsExchangeAlt } from 'react-icons/cg'
import { FaArrowRight } from 'react-icons/fa6'
import { HiArrowSmRight } from 'react-icons/hi'
import { MdOutlineInsights } from 'react-icons/md'
import { TbHexagons, TbLayoutSidebarLeftExpand } from 'react-icons/tb'

import logo from '../../assets/icons/logo.png'
import { SITE_NAME } from '../../utils/site'
import SidebarTab from '../molecules/SidebarTab'

type Props = {
    menu?: Array<{
        title: string
        src: JSX.Element
        href: string
    }>
}

const Sidebar = (props: Props) => {
    const {
        menu = [
            { title: 'OverView', src: <MdOutlineInsights className={'w-6 h-6'} />, href: '/overview' },
            { title: 'My Retirements', src: <BsBoxArrowInDown className={'w-6 h-6'} />, href: '/retirements' },
            { title: 'Pools', src: <TbHexagons className={'w-6 h-6'} />, href: '/pools' },
            { title: 'Exchange ', src: <CgArrowsExchangeAlt className={'w-6 h-6'} />, href: '/exchange' },
            // { title: 'Setting', src: 'Setting' },
        ],
    } = props

    const [open, setOpen] = React.useState(true)
    const [selected, setSelected] = React.useState(0)
    const navigate = useRouter()
    const onButtonClick = (index: number, href: string) => {
        setSelected(index)
        navigate.push(href)
    }
    // ` ${
    //     !open ? 'rotate-180' : ''
    // }`
    return (
        <div
            className={cn('relative h-screen  p-5 pt-8  shadow-md shadow-primary duration-300', {
                'w-72': open,
                'w-20': !open,
            })}
        >
            <HiArrowSmRight
                className={cn(
                    'absolute -right-2.5 top-10 h-5 w-5 bg-primary border-1 border-primary  rounded  cursor-pointer',
                    {
                        'rotate-180': !open,
                    }
                )}
                onClick={() => setOpen(!open)}
            />
            <div
                className="flex items-center gap-x-4"
                onClick={() => navigate.push('/')}
                role="button"
                tabIndex={0}
                onKeyUp={(e) => {
                    if (e.key === 'Enter') {
                        navigate.push('/')
                    }
                }}
            >
                <Image
                    alt="logo"
                    src={logo}
                    className={cn('h-10 w-10 cursor-pointer duration-500', {
                        'rotate-[360deg]': open,
                    })}
                />
                <h1
                    className={cn('origin-right text-2xl font-medium duration-200 ease-in-out', {
                        'scale-0': !open,
                    })}
                >
                    {SITE_NAME}
                </h1>
            </div>
            <ul className="pt-6">
                {menu.map((item, index) => (
                    <li key={index}>
                        <SidebarTab
                            index={index}
                            item={item}
                            selected={selected}
                            open={open}
                            onButtonClick={onButtonClick}
                        ></SidebarTab>
                    </li>
                ))}
            </ul>
        </div>
    )
}

export default Sidebar
