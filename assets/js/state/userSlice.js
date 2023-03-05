import { createSlice } from '@reduxjs/toolkit'

export const userSlice = createSlice({
  name: 'user',
  initialState: {
    user: null,
    relays: {}
  },
  reducers: {
    setUser: (state, action) => {
      state.user = action.payload
    },
    setRelay: (state, action) => {
      relays = {...state.relays}
      relays[action.payload.url] = action.payload.value
      state.relays = relays
    },
    setRelays: (state, action) => {
      if(state.user){
        state.user.relays = action.payload
      }
    }
  },
})

// Action creators are generated for each case reducer function
export const { setUser, setRelay, setRelays } = userSlice.actions

export default userSlice.reducer