import React, { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom"
import axios from "axios"
import { nip19 } from "nostr-tools";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import { useTitle, ReloadPosts } from "../components/ui_elements"
import { UserItem } from "../components/user"

export default function Search(){
  useTitle("Search", [])
  const [focus, setFocus] = useState(false)

  let [searchParams, setSearchParams] = useSearchParams();
  const [term, setTerm] = useState(searchParams.get("s") || "")
  const [users, setUsers] = useState([])
  const [loadingState, setLoadingState] = useState("ok")

  function getUsers(t){
    let search = t || term
    let path = "/api/v1/search"
    let params = {s: search}
    try{
      pubkey = nip19.decode(search).data
      path = "/api/v1/user"
      params = {pubkey: pubkey}
    }catch(e){}
    setLoadingState("loading")
    axios.get(path, {params: params})
    .then(function(resp){
      setLoadingState("ok")
      if(resp.data.users){
        setUsers(resp.data.users)
      }else{
        setUsers([resp.data])
      }
    })
    .catch(function(){
      setLoadingState("err")
    })
  }
  function handleChange(e){
    setTerm(e.target.value)
  }

  function submit(e){
    e.preventDefault()
    setSearchParams({s: term})
    // getUsers()
  }

  useEffect(() => {
    let t = searchParams.get("s")
    if(t){
      setTerm(t)
    }
    if(t && t != ""){
      getUsers(t)
    }
  }, [searchParams])

  // useEffect(() => {
  //   if(term != ""){
  //     getUsers()
  //   }
  // }, [])

  let user_components = users.map((user) => {
    return <UserItem user={user} key={user.id} description={true} />
  })

  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>Search</h2>
      </MainHeader>
      <div className="padding">
        <div className="search-bar-container">
          <form onSubmit={submit}>
            <div className={"search-bar" + (focus ? " focus" : "")} >
              <i className="micon search"></i>
              <input type="text" 
                name="s"
                placeholder="Search user npub, nip5 or name" 
                onFocus={(e) => setFocus(true)} 
                onBlur={() => setFocus(false)}
                value={term}
                onChange={handleChange}
                ></input>
            </div>
          </form>
        </div>
      </div>
      {loadingState != "ok" ?
        <ReloadPosts reload={getUsers} state={loadingState} /> :
        user_components
      }
    </div>
  )
}