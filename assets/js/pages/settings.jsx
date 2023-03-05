import React, { useEffect, useState } from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import { useTitle } from "../components/ui_elements"

import { useSelector, useDispatch } from 'react-redux'
import { useNavigate } from "react-router-dom";
import { getContactList, getMetadataEvent, sign } from "../nostr";
import { publishEvent, postEvent, connectedRelayCount } from "../relay";
import { setRelays, setUser } from "../state/userSlice";

export default function Settings(){
  useTitle("Settings")
  const user = useSelector((state) => state.user.user)
  let navigate = useNavigate();
  // useEffect(function(){
  //   if(user == null) navigate("/")
  // }, [user])

  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>Settings</h2>
      </MainHeader>
      {user &&
        <div className="padding">
          <h3>Profile</h3>
            <ProfileEditor user={user} />
          <h3>Relays</h3>
            <RelayEditor user={user} />
      </div>
      }
    </div>
  )
}

function ProfileEditor(props){
  let user = props.user
  const [profile, setProfile] = useState(user ? {
    name: user.name,
    username: user.username,
    picture: user.picture,
    banner: user.banner,
    nip5: user.nip5,
    about: user.about,
    website: user.website,
    lud06: user.lud06,
    lud16: user.lud16,
  } : {})
  const dispatch = useDispatch()

  function onChange(e){
    let update = {}
    update[e.target.name] = e.target.value
    setProfile((prev) => {
      return Object.assign({}, prev, update);
    })
  }

  async function onSubmit(e){
    e.preventDefault()
    if(connectedRelayCount() == 0){
      alert("You are not connected to any relays! Check the settings page to edit your relays.")
      return 
    }
    let metadata = await getMetadataEvent()
    let content = JSON.parse(metadata.content)
    for(const [key, value] of Object.entries(profile)){
      content[key] = value
    }
    metadata.content = JSON.stringify(content)
    metadata.created_at = Math.floor(Date.now() / 1000)
    metadata = await sign(metadata)
    publishEvent(metadata)
    let newUser = Object.assign({}, user, profile)
    dispatch(setUser(newUser))
  }
  return (
    <form onSubmit={onSubmit}>
      <label>
        Name:
        <input type="text" name="name" value={profile.name || ""}
          onChange={onChange}></input>
      </label>
      <label>
        Username:
        <input type="text" name="username" value={profile.username || ""}
          onChange={onChange}></input>
      </label>
      <label>
        Picture URL:
        <input type="text" name="picture"  value={profile.picture || ""}
        onChange={onChange}></input>
      </label>
      <label>
        Banner URL:
        <input type="text" name="banner"  value={profile.banner || ""}
        onChange={onChange}></input>
      </label>
      <label>
        NIP 5:
        <input type="text" name="nip5"  value={profile.nip5 || ""}
        onChange={onChange}></input>
      </label>
      <label>
        Website:
        <input type="text" name="website"  value={profile.website || ""}
        onChange={onChange}></input>
      </label>
      <label>
        About:
        <textarea name="about" value={profile.about || ""} 
        onChange={onChange}></textarea>
      </label>
      <label>
        LUD 06:
        <input type="text" name="lud06"  value={profile.lud06 || ""}
        onChange={onChange}></input>
      </label>
      <label>
        LUD 16:
        <input type="text" name="lud16"  value={profile.lud16 || ""}
        onChange={onChange}></input>
      </label>
      <button className="btn flat long">
        Submit
      </button>
    </form>
  )
}

function RelayEditor(props){
  const user = props.user
  const [editMode, setEditMode] = useState(false)
  const [edits, setEdits] = useState(user.relays)
  const [newRelay, setNewRelay] = useState("wss://")
  const connectedRelays = useSelector((state) => state.user.relays)
  const dispatch = useDispatch()


  function toggleEditMode(){
    setEdits(user.relays)
    setEditMode(!editMode)
  }

  function setFlag(e, flag, i){
    setEdits((prev) => {
      let newState = [...prev]
      let update = {}
      update[flag] = e.target.checked
      newState[i]= Object.assign({}, newState[i], update)
      return newState
    })
  }

  function deleteRelay(i){
    setEdits((prev) => {
      let newState = [...prev]
      newState.splice(i, 1)
      return newState
    })
  }

  function addRelay(e){
    let url = newRelay
    if(url.startsWith("wss://")){
      setEdits((prev) => {
        let newState = [...prev]
        newState.push({
          url: url,
          read: true,
          write: true,
          global: false
        })
        return newState
      })
      setNewRelay("wss://")
    }
  }

  async function save(){
    console.log(edits)
    let content = {}
    for(let i = 0; i < edits.length; i++){
      content[edits[i].url] = {
        read: !!edits[i].read,
        write: !!edits[i].write
      }
    }
    dispatch(setRelays(edits))
    setEditMode(false)
    let event = await getContactList()
    event.content = JSON.stringify(content)
    event.created_at = Math.floor(Date.now() / 1000)
    event = await sign(event)
    await postEvent(event)
    publishEvent(event)
    console.log(event)
  }

  let relayComponents = edits.map((relay, i) => {
    let status
    if(connectedRelays[relay.url] == true){
      status = "green"
    }else if(connectedRelays[relay.url] == false){
      status = "red"
    }else{
      status = "gray"
    }
    return <div className="relay-item" key={i}>
      <div className={"relay-item-status " + status}></div>
      <div className="relay-item-url">{relay.url}</div>
      <div className="relay-item-settings">
        <input type="checkbox" 
          checked={relay.read} disabled={!editMode}
          onChange={(e) => setFlag(e, "read", i)}></input>
        <input type="checkbox" 
        checked={relay.write} disabled={!editMode}
        onChange={(e) => setFlag(e, "write", i)}></input>
        { editMode && 
        <i className="relay-item-remove micon close" 
        onClick={() => deleteRelay(i)}></i>}
      </div>
    </div>
  })
  return (
    <div className="relay-list">
      <div className="relay-item">
        <div className="relay-item-status"></div>
        <div className="relay-item-url">Relay</div>
        <div className="relay-item-settings">
          <div>R</div>
          <div>W</div>
          {editMode && <div>D</div>}
        </div>
      </div>

      {user && user.relays && relayComponents}
      {editMode &&
        <div className="row">
          <input type="text" placeholder="wss://" 
          value={newRelay} 
          onChange={(e) => setNewRelay(e.target.value)}></input>
          <button className="btn flat long" onClick={addRelay}>Add</button>
        </div>
      }
      <div className="row">
        <button className="btn flat long" onClick={toggleEditMode}>
          {editMode ? "Cancel" : "Edit"}
        </button>
        {editMode && 
          <button className="btn flat long" onClick={save}>
            Save
          </button>
        }
      </div>
    </div>
  )
}