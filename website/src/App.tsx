import React from 'react';
import { BrowserRouter, useLocation, useRoutes } from 'react-router-dom';
import { routes } from '@/routes';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';

const AppContent: React.FC = () => {
  const routeElements = useRoutes(routes);

  return (
    <>

      <div className="min-h-screen flex flex-col bg-zap-bg text-zap-ink">
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:fixed focus:left-3 focus:top-3 focus:z-[60] focus:rounded-lg focus:border focus:border-zap-bg-alt-bright focus:bg-zap-brand focus:px-4 focus:py-2.5 focus:text-sm focus:font-semibold focus:text-white focus:shadow-none focus:outline-none focus:ring-2 focus:ring-zap-accent"
        >
          Skip to content
        </a>
        <Header />
        <div className="flex-1">
          {routeElements}
        </div>
        <Footer />
      </div>
    </>
  );
};

const App: React.FC = () => (
  <BrowserRouter>
    <AppContent />
  </BrowserRouter>
);

export default App;
