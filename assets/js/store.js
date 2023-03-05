import { configureStore } from '@reduxjs/toolkit'

import postReducer from './state/postSlice'
import userReducer from './state/userSlice'

export default configureStore({
  reducer: {
    posts: postReducer,
    user: userReducer
  },
})