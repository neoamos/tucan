import React, { useState, useEffect } from "react";
import axios from 'axios';

import { useNavigate } from "react-router-dom";
import { useSelector } from 'react-redux'

import { UserItem } from "./user"
import { Pagination } from "./ui_elements";

export default function Sidebar(props){
  const page_size = 30
  const user = useSelector((state) => state.user.user)
  const navigate = useNavigate()

  const [following, setFollowing] = useState([])
  const [focus, setFocus] = useState(false)
  const [term, setTerm] = useState("")
  const [total_items, setTotalItems] = useState(0)
  const [page, setPage] = useState({
    page: 1, offset: 0, limit: page_size}
  )

  function getUsers(){
    if(user){
      axios
      .get("/api/v1/users", {params: {following: user.pubkey, offset: page.offset, limit: page.limit}})
      .then(function(resp){
        setTotalItems(resp.data.count)
        setFollowing(resp.data.users)
      })
    }else{
      setFollowing([])
    }
  }
  useEffect(() => {
    setTotalItems(0)
    setPage({page: 1, offset: 0, limit: page_size})
  }, [user])

  useEffect(() => {
    getUsers()
  }, [page])

  function handleChange(e){
    setTerm(e.target.value)
  }
  function submit(e){
    e.preventDefault()
    setTerm("")
    navigate({pathname: "/search", search: ("?s="+term)})
  }

  function handlePagination(pageNum, offset, limit){
    setPage({
      page: pageNum,
      offset: offset,
      limit: limit
    })
  }

  let following_components = following.map((u) => {
    return <UserItem user={u} description={false} key={u.id} />
  })
  return (
    <div className="sidebar">
      <form onSubmit={submit} className="search-bar-container">
        <div className={"search-bar" + (focus ? " focus" : "")} >
          <i className="micon search"></i>
          <input type="text" placeholder="Search Users" 
            onFocus={(e) => setFocus(true)} 
            onBlur={() => setFocus(false)}
            onChange={handleChange}
            value={term}
            ></input>
        </div>
      </form>

      <div className="sidebar-following">
        {following_components}
        {total_items > page_size && <Pagination total_items={total_items} page_size={page_size} page={page.page} fetch={handlePagination} />}
      </div>
    </div>
  )
}