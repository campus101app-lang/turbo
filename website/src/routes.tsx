import { wrap } from "framer-motion";
import React, { lazy } from "react";
import { Navigate, type RouteObject } from "react-router-dom";

// import DashboardLayout from "@/components/layout/DashboardLayout";
// import { TERMINAL_DEFAULT_PATH } from "@/constants/terminalNav";
// import { wrap, protect } from "@/utils/routes";

/* eslint-disable react-refresh/only-export-components */
const LandingPage = lazy(() => import("@/pages/LandingPage"));

export const routes: RouteObject[] = [
  { path: "/", element: <LandingPage /> },
];
