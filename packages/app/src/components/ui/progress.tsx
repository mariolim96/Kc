'use client'

import * as React from 'react'
import * as ProgressPrimitive from '@radix-ui/react-progress'
import { cn } from 'utils/utils'

const Progress = React.forwardRef<
    React.ElementRef<typeof ProgressPrimitive.Root>,
    React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>
>(({ className, value, ...props }, ref) => (
    <ProgressPrimitive.Root
        ref={ref}
        className={cn('bg-primary/20 relative h-2 w-full overflow-hidden rounded-full', className)}
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...props}
    >
        <ProgressPrimitive.Indicator
            className="bg-primary h-full w-full flex-1 transition-all"
            style={{ transform: `translateX(-${100 - (value || 0)}%)` }}
        />
    </ProgressPrimitive.Root>
))
Progress.displayName = ProgressPrimitive.Root.displayName
Progress.propTypes = ProgressPrimitive.Root.propTypes
export { Progress }

export default Progress
