import React, { useState, useEffect } from 'react';

const App = () => {
  const [appVersion, setAppVersion] = useState<string | null>(null);

  useEffect(() => {
    setAppVersion(document.body.getAttribute('data-app-version'));
  }, [appVersion])

  if (!appVersion) {
    return 'Loading...';
  }

  return (
    <div>
      <h1>Derivativo</h1>
      <p>{`Version ${appVersion}`}</p>
    </div>
  );
};

export default App;
