import React from 'react'
import PropTypes from 'prop-types'
import { cn } from 'utils/utils'

function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
    // eslint-disable-next-line react/jsx-props-no-spreading
    return <div className={cn('bg-primary/10 animate-pulse rounded-md', className)} {...props} />
}
Skeleton.displayName = 'Skeleton'
Skeleton.propTypes = {
    className: PropTypes.string,
}
Skeleton.defaultProps = {
    className: '',
}

export { Skeleton }
export default Skeleton
