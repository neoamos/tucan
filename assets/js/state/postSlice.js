import { createSlice } from '@reduxjs/toolkit'

let addPostsHelper = (state, posts) => {
  let posts_map = {}
  for(let i = 0; i < posts.length; i++){
    posts_map[posts[i].event_id] = posts[i]
  }
  return {
    ...state,
    ...posts_map
  }
}

export const postSlice = createSlice({
  name: 'posts',
  initialState: {
    timeline: [],
    posts: {},
    reply_chains: {},
    reply_lists: {},
    feed: (window.localStorage.getItem("feed") || "Global")
  },
  reducers: {
    setTimeline: (state, action) => {
      state.posts = addPostsHelper(state.posts, action.payload)
      state.timeline = action.payload.map((p) => p.event_id)
    },
    pushTimeline: (state, action) => {
      state.posts = addPostsHelper(state.posts, action.payload)
      let ids = action.payload.map((p) => p.event_id)
      state.timeline = state.timeline.concat(ids)
    },
    setFeed: (state, action) => {
      window.localStorage.setItem("feed", action.payload)
      state.feed=action.payload
    },
    setReplyChain: (state, action) => {
      state.posts = addPostsHelper(state.posts, action.payload.reply_chain)
      let event_ids = action.payload.reply_chain.map((p) => p.event_id)
      state.reply_chains[action.payload.event_id] = event_ids
    },
    setReplyList: (state, action) => {
      state.posts = addPostsHelper(state.posts, action.payload.reply_list)
      let event_ids = action.payload.reply_list.map((p) => p.event_id)
      state.reply_lists[action.payload.event_id] = event_ids
    },
    addPosts: (state, action) => {
      state.posts = {
        ...state.posts,
        ...action.payload
      }
    },
    addPost: (state, action) => {
      state.posts[action.payload.event_id] = action.payload
    }
  },
})

// Action creators are generated for each case reducer function
export const { setTimeline, pushTimeline, setReplyChain, setReplyList, 
  addPosts, addPost, setFeed } = postSlice.actions

export default postSlice.reducer