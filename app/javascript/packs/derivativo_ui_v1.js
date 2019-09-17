// app css entry point
import '../derivativo_ui_v1/stylesheets/derivativo_ui_v1.scss';

import React from 'react'
import ReactDOM from 'react-dom'

import App from '../derivativo_ui_v1/App';

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    <App />,
    document.getElementById('derivativo-ui-v1-app'),
  )
})
