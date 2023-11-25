import React from 'react'
import cn from '@/utils/utils'

type Props = {
    onButtonClick: (index: number, href: string) => void
    index: number
    item: { title: string; src: JSX.Element; href: string }
    selected: number
    open: boolean
}

const SidebarTab = (props: Props) => {
    const { onButtonClick, index, item, selected, open } = props
    return (
        <div
            tabIndex={0}
            onClick={() => onButtonClick(index, item.href)}
            onKeyDown={(e) => {
                if (e.key === 'Enter') onButtonClick(index, item.href)
            }}
            role="button"
            className={cn(
                'mt-2 flex cursor-pointer items-center gap-x-4 whitespace-nowrap rounded-md p-2 text-lg hover:bg-primary transition-bg-color shadow shadow-primary duration-300 ease-in-out',
                {
                    'bg-primary shadow-': index === selected,
                }
            )}
        >
            <div>{item.src}</div>
            <h1 className={cn('origin-left duration-200 ease-in-out', { 'scale-0': !open })}>{item.title}</h1>
        </div>
    )
}

export default SidebarTab
