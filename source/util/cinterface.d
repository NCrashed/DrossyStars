// written in the D programming language
/*
*   This file is part of DrossyStars.
*   
*   DrossyStars is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*   
*   DrossyStars is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*   
*   You should have received a copy of the GNU General Public License
*   along with DrossyStars.  If not, see <http://www.gnu.org/licenses/>.
*/
/**
*   Copyright: © 2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*/
module util.cinterface;

import std.typetuple;
import std.traits;
import util.functional;

/**
*   Checks $(B Type) to satisfy compile-time interfaces listed in $(B Interfaces). 
*
*   $(B Type) should expose all methods and fields that are defined in each interface.
*   Compile-time interface description is struct with fields and methods without 
*   implementation. There are no implementations to not use the struct in usual way,
*   linker will stop you. 
*/
template isExpose(Type, Interfaces...)
{
    private template getMembers(T)
    {
        alias getMembers = Tuple!(__traits(allMembers, T));
    }
    
    private template bindType(Base, TS...)
    {
        enum T = TS[0];
        alias bindType = Tuple!(typeof(mixin(Base.stringof ~ "." ~ T)), T);
    }
    
    template isExposeSingle(Interface)
    {
        alias intMembers = StrictTuple!(getMembers!Interface); 
        alias intTypes = StrictTuple!(staticReplicate!(Interface, intMembers.expand!().length));
        alias pairs = staticMap2!(bindType, staticRobin!(intTypes, intMembers));
                
        template checkMember(TS...)
        {
            alias MemberType = TS[0];
            enum MemberName = TS[1];
            
            static if(hasMember!(Type, MemberName))
            {
                enum checkMember = is(typeof(mixin(Type.stringof ~ "." ~ MemberName)) == MemberType);
            }
            else
            {
                enum checkMember = false;
            }
        }
        
        enum isExposeSingle = allSatisfy2!(checkMember, pairs); 
    }
    
    enum isExpose = allSatisfy!(isExposeSingle, Interfaces);
}
/// Example
version(unittest)
{
    struct CITest1
    {
        string a;
        string meth1();
        bool meth2();
    }
    
    struct CITest2
    {
        bool delegate(string) meth3();
    }
    
    struct CITest3
    {
        bool meth1();
    }
    
    struct Test1
    {
        string meth1() {return "";}
        bool meth2() {return true;}
        
        string a;
        
        bool delegate(string) meth3() { return (string) {return true;}; };
    }
    
    static assert(isExpose!(Test1, CITest1, CITest2));
    static assert(!isExpose!(Test1, CITest3));
}