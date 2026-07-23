'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Camera, Menu, X, LogOut } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { ThemeToggle } from '@/components/theme-toggle'
import { cn } from '@/lib/utils'

interface NavbarProps {
  user?: {
    id: string
    username: string
    email: string
  } | null
}

export function Navbar({ user }: NavbarProps) {
  const [isOpen, setIsOpen] = useState(false)

  const navLinks = [
    { label: 'Features', href: '#features' },
    { label: 'Pricing', href: '#pricing' },
    { label: 'About', href: '#about' },
  ]

  return (
    <nav className="sticky top-0 z-50 border-b bg-background/80 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2 flex-shrink-0">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <Camera className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold text-primary">YohPal Mesh</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-1">
            {!user && navLinks.map((link) => (
              <Button key={link.href} variant="ghost" size="sm">
                <Link href={link.href}>{link.label}</Link>
              </Button>
            ))}
          </div>

          {/* Desktop Auth & Theme */}
          <div className="hidden md:flex items-center space-x-4">
            <div className="w-px h-6 bg-border" />
            {user ? (
              <>
                <Button variant="ghost" size="sm" >
                  <Link href="/dashboard">Dashboard</Link>
                </Button>
                <DropdownMenu>
                  <DropdownMenuTrigger >
                    <button className="inline-flex shrink-0 items-center justify-center rounded-2xl border border-border bg-background px-3 h-7 gap-1 text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/30 hover:bg-muted hover:text-foreground">
                      {user.username}
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem >
                      <Link href="/settings/profile" className="cursor-pointer">
                        Profile Settings
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem >
                      <Link href="/settings/security" className="cursor-pointer">
                        Security
                      </Link>
                    </DropdownMenuItem>
                    <div className="my-2 border-t" />
                    <DropdownMenuItem
                      
                      className="cursor-pointer text-red-600"
                    >
                      <form action="/api/auth/logout" method="POST">
                        <button type="submit" className="w-full text-left flex items-center">
                          <LogOut className="w-4 h-4 mr-2" />
                          Log Out
                        </button>
                      </form>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </>
            ) : (
              <>
                <Button variant="ghost" size="sm" >
                  <Link href="/auth/login">Log In</Link>
                </Button>
                <Button size="sm" >
                  <Link href="/auth/signup">Get Started</Link>
                </Button>
              </>
            )}
            <ThemeToggle />
          </div>

          {/* Mobile Menu Button & Theme */}
          <div className="flex md:hidden items-center space-x-2">
            <ThemeToggle />
            <DropdownMenu open={isOpen} onOpenChange={setIsOpen}>
              <DropdownMenuTrigger >
                <button className="inline-flex shrink-0 items-center justify-center rounded-2xl border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/30 hover:bg-muted hover:text-foreground size-10">
                  {isOpen ? (
                    <X className="h-5 w-5" />
                  ) : (
                    <Menu className="h-5 w-5" />
                  )}
                  <span className="sr-only">Toggle menu</span>
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-48">
                {!user && navLinks.map((link) => (
                  <DropdownMenuItem key={link.href} >
                    <Link href={link.href} className="cursor-pointer">
                      {link.label}
                    </Link>
                  </DropdownMenuItem>
                ))}
                {user && (
                  <>
                    <DropdownMenuItem >
                      <Link href="/dashboard" className="cursor-pointer">
                        Dashboard
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem >
                      <Link href="/settings/profile" className="cursor-pointer">
                        Profile
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem >
                      <Link href="/settings/security" className="cursor-pointer">
                        Security
                      </Link>
                    </DropdownMenuItem>
                  </>
                )}
                <div className="my-2 border-t" />
                {!user ? (
                  <>
                    <DropdownMenuItem >
                      <Link href="/auth/login" className="cursor-pointer">
                        Log In
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem >
                      <Link href="/auth/signup" className="cursor-pointer">
                        Get Started
                      </Link>
                    </DropdownMenuItem>
                  </>
                ) : (
                  <DropdownMenuItem  className="text-red-600">
                    <form action="/api/auth/logout" method="POST">
                      <button type="submit" className="w-full text-left">
                        Log Out
                      </button>
                    </form>
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </nav>
  )
}
