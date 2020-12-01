import React, { useState } from 'react';
import { BrowserRouter } from 'react-router-dom';
import styled, { ThemeProvider } from 'styled-components';
import GlobalStyles from './styles/GlobalStyles';
import { lightTheme, darkTheme } from './styles/Theme';
import { Sun, Moon } from './components/Icons';
import Routes from './routes';

const Button = styled.button`
  position: fixed;
  right: 1rem;
  bottom: 1rem;
  svg {
    fill: ${(props) => props.theme.text};
  }
`;

const App: React.FC = () => {
  const [isLight, setIsLight] = useState(true);

  const toggleTheme = () => {
    setIsLight(!isLight);
  };

  return (
    <ThemeProvider theme={isLight ? lightTheme : darkTheme}>
      <GlobalStyles />
      <Button onClick={toggleTheme}>
        {isLight ? <Sun size={36} /> : <Moon size={36} />}
      </Button>
      <BrowserRouter>
        <Routes />
      </BrowserRouter>
    </ThemeProvider>
  );
};

export default App;
