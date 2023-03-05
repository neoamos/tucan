import React, { useState, useEffect, useRef } from "react";
import { useParams, useLocation } from 'react-router-dom';

import { useSelector, useDispatch } from 'react-redux'
import { setReplyChain, setReplyList, addPosts, addPost } from '../state/postSlice'

import { ExpandedPost, TimelinePost } from "../components/post";

import { Loader, ReloadPosts, useTitle } from "../components/ui_elements"
import { MainHeader } from "../layout";
import PostForm from "../components/post_form"
import { ScrollHere } from "../components/scroll"
import axios from "axios";
import { nip19 } from "nostr-tools";

let offsetTop = null
export default function Post(){
  const dispatch = useDispatch()

  const { post_id } = useParams()
  event_id = nip19.decode(post_id).data
  const { pathname } = useLocation()

  const post = useSelector((state) => state.posts.posts[event_id])

  const reply_chain_ids = useSelector((state) => (state.posts.reply_chains[event_id]))
  const reply_chain = useSelector((state) => {
    return reply_chain_ids ? 
      reply_chain_ids.map((id) => state.posts.posts[id]) : null
  })

  const reply_list_ids = useSelector((state) => (state.posts.reply_lists[event_id]))
  const replies = useSelector((state) => {
    return reply_list_ids ?   
      reply_list_ids.map((id) => state.posts.posts[id]) : null
  })

  const [ replyReady, setReplyReady] = useState(false)

  const ref = useRef(null);

  useTitle("Post", [])

  const [loadingState, setLoadingState] = useState(true)
  function getReplies(){
    setLoadingState("loading")
    axios
    .get("/api/v1/replies", {params: {post_id: event_id}})
    .then(function(resp){
      setLoadingState("ok")
      dispatch(setReplyList({event_id: event_id, reply_list: resp.data.posts}))
    })
    .catch(function(){
      setLoadingState("err")
    })
  }

  useEffect(() => {
    window.scrollTo(0, ref.current.offsetTop - 53)
  }, [post])

  useEffect(() => {
    axios
    .get("/api/v1/post", {params: {post_id: event_id}})
    .then(function(resp){
      dispatch(addPost(resp.data))
      setReplyReady(true)
    })
  }, [pathname])

  useEffect(() => {
    if(!replies){
      getReplies()
    }else{
      setLoadingState("ok")
    }
  }, [pathname])

  useEffect(() => {
    axios
    .get("/api/v1/reply_chain", {params: {post_id: event_id}})
    .then((resp) => {
      offsetTop = ref.current.offsetTop
      dispatch(setReplyChain({event_id: event_id, reply_chain: resp.data.posts}))
    })
  }, [pathname])

  useEffect(() => {
    // setTimeout(() => setShowSpacer(false), 1000)
    if(offsetTop){
      let scroll_by = ref.current.offsetTop - offsetTop
      window.scrollBy(0, scroll_by)
      offsetTop = null
    }
  }, [reply_chain])

  let reply_chain_components = (reply_chain || []).map((p, i) => {
    return <TimelinePost post={p} replyLine={true} key={p.id} isReply={i>0}></TimelinePost>
  })
  let reply_components = (replies || []).map((p) => {
    return <TimelinePost post={p} key={p.id}></TimelinePost>
  })
  return (
    <div style={{height: "100%"}}>
      <MainHeader>
        <h2>Post</h2>
      </MainHeader>
      {reply_chain_components}
      <span ref={ref} />
      { post && 
        <>
          <ExpandedPost post={post} isReply={reply_chain && reply_chain.length > 0} />
          <PostForm reply={true} inline={true} reply_to={post} enabled={replyReady} />
        </>
      }
      <ReloadPosts reload={getReplies} state={loadingState} />
      {reply_components}
    </div>

  )
}