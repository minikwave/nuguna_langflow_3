import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { MainLayout } from '../layouts/MainLayout';
import { LoginPage } from '../pages/auth/LoginPage';
import { RegisterPage } from '../pages/auth/RegisterPage';
import { PromptListPage } from '../pages/prompt/PromptListPage';
import { PromptDetailPage } from '../pages/prompt/PromptDetailPage';
import { PromptCreatePage } from '../pages/prompt/PromptCreatePage';
import { PromptEditPage } from '../pages/prompt/PromptEditPage';
import { TeamListPage } from '../pages/team/TeamListPage';
import { TeamDetailPage } from '../pages/team/TeamDetailPage';
import { TeamCreatePage } from '../pages/team/TeamCreatePage';
import { TeamEditPage } from '../pages/team/TeamEditPage';

interface PrivateRouteProps {
    children: React.ReactNode;
}

const PrivateRoute: React.FC<PrivateRouteProps> = ({ children }) => {
    const { user } = useSelector((state: RootState) => state.auth);
    return user ? <>{children}</> : <Navigate to="/login" />;
};

export const AppRoutes: React.FC = () => {
    return (
        <Routes>
            {/* 공개 라우트 */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

            {/* 인증이 필요한 라우트 */}
            <Route
                path="/"
                element={
                    <PrivateRoute>
                        <MainLayout />
                    </PrivateRoute>
                }
            >
                {/* 프롬프트 관련 라우트 */}
                <Route index element={<Navigate to="/prompts" replace />} />
                <Route path="prompts" element={<PromptListPage />} />
                <Route path="prompts/new" element={<PromptCreatePage />} />
                <Route path="prompts/:id" element={<PromptDetailPage />} />
                <Route path="prompts/:id/edit" element={<PromptEditPage />} />

                {/* 팀 관련 라우트 */}
                <Route path="teams" element={<TeamListPage />} />
                <Route path="teams/new" element={<TeamCreatePage />} />
                <Route path="teams/:id" element={<TeamDetailPage />} />
                <Route path="teams/:id/edit" element={<TeamEditPage />} />
            </Route>

            {/* 404 페이지 */}
            <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
    );
}; 