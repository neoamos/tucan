
import React, { useEffect, useState } from "react";
import axios from "axios";
import { Outlet, NavLink, useLocation, useNavigate, useParams, Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import ProfilePicture from "./components/profile_picture"
import Sidebar from "./components/sidebar"
import { profile_path, user_at } from "./url_helpers"
import he from "he"

import { setUser } from './state/userSlice'
import { setFeed, setTimeline } from './state/postSlice'

import { useRelays } from "./relay";

import { useSelector, useDispatch } from 'react-redux'
import { Menu } from "./components/ui_elements";
// import { setUser } from '../state/postSlice'

const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
axios.defaults.headers.post["X-CSRF-Token"] = token

export function Layout(){
  const user = useSelector((state) => state.user.user)

  const dispatch = useDispatch()

  useRelays()

  useEffect(() => {
    if(false && window.user){
      let user = JSON.parse(he.decode(window.user))
      dispatch(setUser(user)) 
    }else{
      axios.get("/api/v1/current_user")
      .then(function(resp){
        dispatch(setUser(resp.data)) 
      })
    }
  }, [])

  return (
    <div id="app-root">
      <MobileNav />
      <div id="left">
        <div className="desktop-nav">
          <div className="desktop-nav-header">
          <Link to={"/"}>
            <div className="logo ts">
              <img src="/images/toucan.png"></img>
            </div>
          </Link>
          </div>
          <NavButtons />
        </div>
        <div className="desktop-nav">
          <UserBadge />
        </div>
      </div>
      <div id="right">
        <div id="body">
          <div id="main">
            <Outlet />
          </div>
          <div id="sidebar">
            <Sidebar />
          </div>
        </div>
      </div>
    </div>
  )
}

export function MobileNav(props){
  const user = useSelector((state) => state.user.user)
  const [open, setIsOpen] = useState(false)
  const dispatch = useDispatch()
  const navigate = useNavigate()

  function logout(){
    setIsOpen(false)
    window.localStorage.removeItem("seckey")
    axios.get("/api/v1/logout").then(function(resp){
      dispatch(setUser(null))
      dispatch(setFeed("Global"))
      dispatch(setTimeline([]))
    })
  }

  let menu = (<div>
    <div className="menu-item" 
      onClick={() => {navigate(profile_path(user.pubkey)); setIsOpen(false)}}>
        Profile
    </div>
    <div className="menu-item" 
      onClick={() => {navigate("/settings"); setIsOpen(false)}}>
        Settings
    </div>
    <div className="menu-item" onClick={logout}>Logout</div>
    <div className="menu-item" 
      onClick={() => {navigate("/about"); setIsOpen(false)}}>
        About
    </div>
  </div>)

  return (
    <div className="mobile-nav">
      <NavLink to={"/"} className="mobile-nav-link">
        <div className="mobile-nav-button btn">
          <i className="micon home"></i>
        </div>
      </NavLink>
      {user &&
        <NavLink to={"/notifications"} className="mobile-nav-link">
          <div className="mobile-nav-button btn">
            <i className="micon notifications"></i>
          </div>
      </NavLink>
      }
      {user &&
        <NavLink to={"/messages"} className="mobile-nav-link">
          <div className="mobile-nav-button btn">
            <i className="micon messages"></i>
          </div>
        </NavLink>
      }
      <NavLink to={"/search"} className="mobile-nav-link">
        <div className="mobile-nav-button btn">
          <i className="micon search"></i>
        </div>
      </NavLink>
      {user &&
        <div className="mobile-nav-link">
          <Menu menu={menu} setIsOpen={setIsOpen} open={open}>
            <ProfilePicture 
              src={user.picture} 
              to={profile_path(user.pubkey)} 
              type="medium"
              onClick={() => setIsOpen(!open)} />
          </Menu>
        </div>
      }
      {!user &&
      <NavLink to={"/login"} className="mobile-nav-link">
        <div className="mobile-nav-button btn">
          <i className="micon login"></i>
        </div>
      </NavLink>
      }
    </div>
  )
}

export function MainHeader(props){
  let navigate = useNavigate();

  function scrollUp(){
    window.scrollTo(0,0)
  }
  return (
    <div className="main-header">
      {props.backButon || true ? 
        <div className="btn back-button" onClick={() => navigate(-1)}>
          <FontAwesomeIcon icon="arrow-left"/>
        </div> : null
      }
      <div className="main-header-body">
        {props.children}
      </div>
      <div className="logo ts mobile">
        <img src="/images/toucan.png"></img>
      </div>
      {/* <div className="btn back-button" onClick={scrollUp}>
        <i className="micon up"></i>
      </div> */}
    </div>
  )
}

function NavButtons(){
  const user = useSelector((state) => state.user.user)
  return (
    <div className="desktop-nav-buttons">
      <NavLink to={"/"} className="desktop-nav-link">
        <div className="desktop-nav-button btn">
          <i className="micon home"></i>
          <span>Home</span>
        </div>
      </NavLink>
      {user && 
        <NavLink to={"/notifications"} className="desktop-nav-link">
          <div className="desktop-nav-button btn">
            <i className="micon notifications"></i>
            <span>Notifications</span>
          </div>
        </NavLink>
      }
      {user && 
        <NavLink to={"/messages"} className="desktop-nav-link">
          <div className="desktop-nav-button btn">
            <i className="micon messages"></i>
            <span>Messages</span>
          </div>
        </NavLink>
      }
      {user && 
        <NavLink to={profile_path(user.pubkey)} className="desktop-nav-link">
          <div className="desktop-nav-button btn">
            <i className="micon person"></i>
            <span>Profile</span>
          </div>
        </NavLink>
      }
      {user && 
        <NavLink to={"/settings"} className="desktop-nav-link">
          <div className="desktop-nav-button btn">
            <i className="micon settings"></i>
            <span>Settings</span>
          </div>
        </NavLink>
      }
      <NavLink to={"/search"} className="desktop-nav-link">
      <div className="desktop-nav-button btn">
        <i className="micon search"></i>
        <span>Search</span>
      </div>
    </NavLink>
      <NavLink to={"/about"} className="desktop-nav-link">
        <div className="desktop-nav-button btn">
          <i className="micon info"></i>
          <span>About</span>
        </div>
      </NavLink>
      {user ?
        <NavLink to={"/new-post"} className="desktop-nav-button btn login">
          <i className="micon edit"></i>
          <span>Post</span>
        </NavLink> :
        <NavLink to={"/login"} className="desktop-nav-button btn login">
          <i className="micon login"></i>
          <span>Login</span>
        </NavLink>
      }
    </div>
  )
}

function UserBadge(){

  const dispatch = useDispatch()
  const [open, setIsOpen] = useState(false)

  function logout(){
    setIsOpen(false)
    window.localStorage.removeItem("seckey")
    axios.get("/api/v1/logout").then(function(resp){
      dispatch(setUser(null))
      dispatch(setFeed("Global"))
      dispatch(setTimeline([]))
    })
  }

  const navigate = useNavigate();
  const user = useSelector((state) => state.user.user)
  let menu = (<div>
    <div className="menu-item" onClick={() => {navigate(profile_path(user.pubkey)); setIsOpen(false)}}>Profile</div>
    <div className="menu-item" onClick={logout}>Logout</div>
  </div>)
  if(user){
    return (
      <Menu menu={menu} setIsOpen={setIsOpen} open={open}>
      <div className="user-badge ts" onClick={() => setIsOpen(!open)}>
        <ProfilePicture src={user.picture} to={profile_path(user.pubkey)} type="medium" />
        <div className="user-badge-sig">
          <div className="name">
            {user.name}
          </div>
          <div className="at">
            {user_at(user)}
          </div>
        </div>
        <div className="user-badge-btn">
          <i className="micon more"></i>
        </div>
      </div>
    </Menu>
    )
  }else{
    return <></>
  }
}

function withRouter(Component) {
  function ComponentWithRouterProp(props) {
    let location = useLocation();
    let navigate = useNavigate();
    let params = useParams();
    return (
      <Component
        {...props}
        router={{ location, navigate, params }}
      />
    );
  }

  return ComponentWithRouterProp;
}