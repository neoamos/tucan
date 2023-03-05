import React, { useState, useEffect } from "react";
import axios from 'axios';
import { nip19 } from "nostr-tools";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import { Pubkey, Loader, ReloadPosts, useTitle, Pagination } from "../components/ui_elements"
import { Link, useParams, useLocation } from "react-router-dom";
import Tabs from "../components/tabs";

import { TimelinePost } from "../components/post"
import { FollowButton } from "../components/user";
import { proxyImage } from "../image";

export default function Profile(props){
  let { pubkey } = useParams()
  try{
    pubkey = nip19.decode(pubkey).data
  }catch(e){}

  const { pathname } = useLocation()

  const page_size = 50;

  const [user, setUser] = useState(null)
  const [posts, setPosts] = useState([])
  const [page, setPage] = useState({tab: 0, page: 1, offset: 0})
  const [total_items, setTotalItems] = useState(0)

  const [loadingState, setLoadingState] = useState("loading")
  const [profileLoadingState, setProfileLoadingState] = useState("loading")

  useTitle((user ? (user.name || "Profile") : "Profile"), [user])

  function setTab(tab){
    setPage({
      tab: tab, page: 1, offset: 0
    })
  }

  function get_posts(with_replies){
    let params = {pubkey: pubkey, count: true, offset: page.offset, limit: page_size}
    if(with_replies){
      params.with_replies = true
    }
    axios
    .get("/api/v1/posts", {params: params})
    .then(function(resp){
      setLoadingState("ok")
      setPosts(resp.data.posts)
      setTotalItems(resp.data.count)
    })
    .catch(function(){
      setLoadingState("err")
    })
  }

  function get_tab(){
    setLoadingState("loading")
    setPosts([])
    if(page.tab == 0){
      get_posts(false)
    }else if(page.tab == 1){
      get_posts(true)
    }else if(page.tab == 2){
      axios
      .get("/api/v1/likes", {params: {pubkey: pubkey, offset: page.offset, limit: page_size}})
      .then(function(resp){
        setLoadingState("ok")
        setPosts(resp.data.posts)
        setTotalItems(resp.data.count)
      })
      .catch(function(){
        setLoadingState("err")
      })
    }
  }

  function get_profile(){
    setUser(null)
    setPosts([])
    setProfileLoadingState("loading")
    axios
    .get("/api/v1/user", {params: {pubkey: pubkey}})
    .then(function(resp){
      setProfileLoadingState("ok")
      setUser(resp.data)
    })
    .catch(function(){
      setProfileLoadingState("err")
    })
  }

  function handlePagination(pageNum, offset, limit){
    setPage({
      ...page,
      page: pageNum,
      offset: offset,
      limit: limit
    })
  }

  useEffect(() => {
    setPage({
      tab: 0, page: 1, offset: 0
    })
    get_profile()
  }, [pathname])

  useEffect(() => {
    window.scrollTo(0,0)
    get_tab()
  }, [pathname, page])

  let tabs = [
    {
      name: "Posts"
    },
    {
      name: "Posts & Replies"
    },
    {
      name: "Likes"
    }
  ]


  let post_components = posts.map((post) => {
    if(post.reply_to){
      return <TimelinePost post={post.reply_to} reply={post} key={post.id}></TimelinePost>
    }else{
      return <TimelinePost post={post} key={post.id}></TimelinePost>
    }
  })
  if(user == null){
    return (
      <div style={{height: "100%"}}>
        <ScrollToTop />
        <MainHeader>
          <h2>Profile</h2>
        </MainHeader>
        <ReloadPosts reload={get_profile} state={profileLoadingState} />
      </div>
    )
  }else{
    return (
      <div style={{height: "100%"}}>
        <ScrollToTop />
        <MainHeader>
          <h2>{user.name || "Profile"}</h2>
        </MainHeader>
        <div className="profile">
          <div className="profile-banner">
            <div className="spacer banner"></div>
            {user.banner && <img src={proxyImage(user.banner, 600, 200, "fill")}></img>}
          </div>
          <div className="profile-avatar">
            <ProfilePicture type="profile" to="/" src={user.picture} />
            <div className="profile-buttons">
              {/* <a className="btn border sm" style={{marginRight: "8px"}}>
                <i className="micon more"></i>
              </a> */}
              <FollowButton user={user} />
            </div>
          </div>
          <div className="profile-sig">
            <h2>{user.name}</h2>
            <div className="profile-at">{user.nip5}</div>
            <Pubkey pubkey={user.pubkey} />
          </div>
          <div className="profile-description">
            {user.about}
          </div>
          {/* <div className="profile-info">
            <i className="micon calendar"></i>
            Joined January 2023
          </div> */}
          <div className="profile-followers">
            <Link to={"/profile/" + nip19.npubEncode(user.pubkey) + "/following"}>
              <span className="number">{user.following_count}</span><span className="tag">Following</span>
            </Link>
            <Link to={"/profile/" + nip19.npubEncode(user.pubkey) + "/followers"}>
              <span className="number">{user.follower_count}</span><span className="tag">Followers</span>
            </Link>
          </div>
        </div>
        <Tabs tabs={tabs} activeTab={page.tab} setActiveTab={setTab}/>
        <div className="profile-notes">
          {loadingState!="ok" ? <ReloadPosts reload={get_tab} state={loadingState} /> : post_components}
        </div>
        {total_items > page_size && <Pagination total_items={total_items} page_size={page_size} page={page.page} fetch={handlePagination} />}
      </div>
    )
  }
  
}

const fallback = "/images/profile.jpg"

function ProfilePicture(props){

  let onError = (e) => {
    e.target.src=fallback
  }
  let src = props.src ? proxyImage(props.src, 134, 134, "fill") : fallback
  return (
    <div className={"pfp profile"}>
      <div className="spacer square"></div>
      <Link onClick={(e) => e.stopPropagation()}>
        <div className="pfp-inner">
          <img src={src} onError={onError}></img>
          <div className="filter ts"></div>
        </div>
      </Link>
    </div>

  )
}