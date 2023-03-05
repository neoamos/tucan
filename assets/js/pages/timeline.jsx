import React, { useState, useEffect } from "react";
import axios from 'axios';

import { MainHeader } from "../layout";

import { TimelinePost } from "../components/post"
import PostForm from "../components/post_form"
import { Menu, ReloadPosts, useTitle } from "../components/ui_elements"

import { useSelector, useDispatch } from 'react-redux'
import { setTimeline, pushTimeline, setFeed } from '../state/postSlice'

function currentScrollPercentage(){
    return (
      (document.documentElement.scrollTop + 
        document.body.scrollTop) 
      / 
      (document.documentElement.scrollHeight - 
        document.documentElement.clientHeight) 
      * 100);
}

export default function Timeline(){

  const user = useSelector((state) => state.user.user)
  const timeline_ids = useSelector((state) => state.posts.timeline)
  const posts = useSelector((state) => {
    return timeline_ids.map((id) => state.posts.posts[id])
  })
  const dispatch = useDispatch()

  const [ loadingState, setLoadingState ] = useState(true)
  const feed = useSelector((state) => state.posts.feed)
  const [ open, setOpen ] = useState(false)

  function setFeedHelper(feed){
    window.localStorage.setItem("feed", feed)
    dispatch(setTimeline([]))
    dispatch(setFeed(feed))
    getTimeline(feed)
  }

  useTitle(feed, [feed])

  function getTimeline(f){
    f = f || feed
    setLoadingState("loading")
    axios
    .get("/api/v1/posts", {params: {feed: f}})
    .then(function(resp){
      setLoadingState("ok")
      setScrollEnded(false)
      dispatch(setTimeline(resp.data.posts))
    })
    .catch(function(){
      setLoadingState("err")
    })
  }

  const [scrollEnded, setScrollEnded] = useState(false)

  function loadMorePosts(before, cb){
    axios
    .get("/api/v1/posts", {params: {before: before, feed: feed}})
    .then(function(resp){
      dispatch(pushTimeline(resp.data.posts))
      setScrollEnded(resp.data.length==0)
      cb()
    })
  }

  useEffect(() => {
    let fetching = false
    window.onscroll = function(e){
      let scroll = document.documentElement.scrollHeight - (document.documentElement.scrollTop +  document.documentElement.clientHeight)
      let test = scroll < 2 * document.documentElement.clientHeight
      if(test && !fetching && !scrollEnded){
        fetching = true
        if(posts.length>0){
          let before = Date.parse(posts[posts.length-1].created_at)
          before = Math.trunc(before/1000)
          loadMorePosts(before, (e) => fetching = false)
        }
      }
    }
    return () => {
      window.onscroll = null
    }
  }, [posts, scrollEnded])

  useEffect(() => {
    if(posts.length == 0){
      getTimeline()
    }else{
      setLoadingState("ok")
    }
  }, [feed])

  let timeline_components = posts.map((post) => {
    if(feed == "Following" && post.reply_to){
      return <TimelinePost post={post.reply_to} reply={post} thread={false} key={post.id} hide_images={false}></TimelinePost>
    }else{
      return <TimelinePost post={post} thread={false} key={post.id} hide_images={false}></TimelinePost>
    }
  })
  let menu = (<div>
    <div className="menu-item" onClick={() => {setFeedHelper("Global"); setOpen(false)}}>Global</div>
    <div className="menu-item" onClick={() => {setFeedHelper("Following"); setOpen(false)}}>Following</div>
    <div className="menu-item" onClick={() => {setFeedHelper("Friends of Friends"); setOpen(false)}}>Friends of Friends</div>
  </div>)
  return (
    <div style={{height: "100%"}}>
      <MainHeader>
        {user ?
          <Menu open={open} setIsOpen={setOpen} menu={menu}>
              <div className="inline" onClick={() => setOpen(true)}>
                <h2 className="header-dropdown" >{feed} <i className="micon chevron_down"></i></h2>
              </div>
          </Menu> :
          <h2>Global</h2>
        }

      </MainHeader>

      <PostForm inline={true} enabled={true} />

      <ReloadPosts reload={() => getTimeline()} state={loadingState} />
      {timeline_components}
    </div>
  )
}