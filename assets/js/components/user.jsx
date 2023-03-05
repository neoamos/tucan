import React, {useState, useEffect, useCallback} from "react";
import { Link, useNavigate } from "react-router-dom";
import { getContactList, sign } from "../nostr";

import { profile_path, user_at } from "../url_helpers";
import ProfilePicture from "./profile_picture";
import { postEvent, connectedRelayCount, publishEvent } from "../relay";
import { debounce } from "../utils";
import { Tooltip } from "react-tippy";
import axios from "axios";

export function UserItem(props){
  const navigate = useNavigate();
  return (
    <div className="user-item" onClick={() => {navigate(profile_path(props.user.pubkey))}}>
      <ProfilePicture src={props.user.picture} to={profile_path(props.user.pubkey)} type="large" />
      <div className="user-item-sig">
        <div className="row-s">
          <div className="flex-grow">
            <div className="name">
              {props.user.name}
            </div>
            <div className="at">
              {user_at(props.user)}
            </div>
          </div>
          {props.follow_button && <FollowButton user={props.user} />}
        </div>
        <div className="about">
          {props.description && props.user.about && props.user.about.slice(0, 125)}
        </div>
      </div>
    </div>
  )
}

export function UserMenuItem(props){
  return (
    <div className="user-item">
      <ProfilePicture src={props.user.picture} type="large" noLink={true} />
      <div className="user-item-sig">
        <div className="row-s">
          <div className="flex-grow">
            <div className="name">
              {props.user.name}
            </div>
            <div className="at">
              {user_at(props.user)}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export function UserSearchMenu(props){
  const [users, setUsers] = useState([])
  const [open, setOpen] = useState(false)

  let getUsers = useCallback(debounce(function(term){
    if(term!=""){
      axios.get("/api/v1/search", {params: {s: term}})
      .then(function(resp){
        setUsers(resp.data.users)
        setOpen(true)
      })
    }
  }, 250), [])

  useEffect(() => {
    getUsers(props.term)
  }, [props.term])

  let userMenu = users.map((u, i) => {
    return (
      <div className="menu-item" onClick={() => props.selectUser(u)}>
        <UserMenuItem user={u} key={i} />
      </div>
    )
  })
  userMenu = <div className="overflow-menu">
    {userMenu}
  </div>
  return (
    <Tooltip
    html={userMenu}
    open={open && props.term.length>0}
    onRequestClose={() => {setOpen(false)}}
    position={props.position || "bottom"}
    interactive={true}
    theme="light"
  >
    {props.children}
  </Tooltip>
  )
}

export function FollowButton(props){
  let user = props.user

  let [followed, setFollowed] = useState(props.user.followed)
  let [disabled, setDisabled] = useState(false)

  async function handleFollow(e){
    console.log("follow btn press")
    e.stopPropagation()
    // let msg = followed ?
    // "Are you sure you want to unfollow this user?":
    // "Are you sure you want to follow this user?";
    let action = followed ? "remove" : "add"
    if(connectedRelayCount() == 0){
      alert("You are not connected to any relays! Check the settings page to edit your relays.")
      return 
    }
    try{
      setDisabled(true)
      let event = await getContactList({action: action, pubkey: user.pubkey})
      event = await sign(event)
      await postEvent(event)
      publishEvent(event)
      setFollowed(!followed)
      console.log(event)
      setDisabled(false)
    }catch{
      setDisabled(false)
    }
  }

  return (
    <button className={"btn follow-btn " + (followed ? "followed" : "black")}
      onClick={handleFollow} disabled={disabled}>
      {followed ? "Following" : "Follow"}
    </button>
  )
}