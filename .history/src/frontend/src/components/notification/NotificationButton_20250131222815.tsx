import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
    IconButton,
    Badge,
    Popover,
    Box,
    Button,
    Divider,
} from '@mui/material';
import {
    Notifications as NotificationsIcon,
} from '@mui/icons-material';
import { markAllAsRead } from '../../store/slices/notificationSlice';
import { RootState, AppDispatch } from '../../store';
import { NotificationList } from './NotificationList';
import { NotificationState } from '../../store/types';

export const NotificationButton: React.FC = () => {
    const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
    const dispatch = useDispatch<AppDispatch>();
    const { unreadCount } = useSelector<RootState, NotificationState>(
        (state) => state.notification
    );

    const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const handleMarkAllAsRead = () => {
        dispatch(markAllAsRead());
    };

    const open = Boolean(anchorEl);
    const id = open ? 'notification-popover' : undefined;

    return (
        <>
            <IconButton
                color="inherit"
                onClick={handleClick}
                aria-describedby={id}
            >
                <Badge badgeContent={unreadCount} color="error">
                    <NotificationsIcon />
                </Badge>
            </IconButton>
            <Popover
                id={id}
                open={open}
                anchorEl={anchorEl}
                onClose={handleClose}
                anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'right',
                }}
                transformOrigin={{
                    vertical: 'top',
                    horizontal: 'right',
                }}
                PaperProps={{
                    sx: {
                        width: 360,
                        maxHeight: 480,
                    },
                }}
            >
                <Box sx={{ p: 2, display: 'flex', justifyContent: 'flex-end' }}>
                    <Button
                        size="small"
                        onClick={handleMarkAllAsRead}
                        disabled={unreadCount === 0}
                    >
                        모두 읽음 표시
                    </Button>
                </Box>
                <Divider />
                <NotificationList />
            </Popover>
        </>
    );
}; 