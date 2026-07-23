import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Navbar } from "@/components/navbar";
import { getCurrentUser } from "@/lib/auth-actions";
import {
  Smartphone,
  Video,
  Users,
  Zap,
  Star,
  Play,
  Download,
  Share2,
  CheckCircle,
  ArrowRight,
  Sparkles,
  Camera
} from "lucide-react";

export default async function Home() {
  const user = await getCurrentUser();

  return (
    <div className="min-h-screen bg-background">
      <Navbar user={user} />

      {/* Hero Section */}
      <section className="relative overflow-hidden py-20 lg:py-32">
        <div className="absolute inset-0 bg-muted/30" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="text-center max-w-4xl mx-auto">


            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight text-foreground mb-8">
              Turn Your{" "}
              <span className="text-primary">
                Mobile Phones
              </span>
              <br />
              Into a Production Studio
            </h1>

            <p className="text-xl text-muted-foreground mb-10 max-w-3xl mx-auto leading-relaxed">
              YohPal Mesh transforms ordinary smartphones into professional multi-camera setups.
              Create stunning productions with intelligent director features, real-time switching,
              and studio-quality output.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16">
              <Button size="lg" className="text-lg px-8 py-6">
                <Play className="w-5 h-5 mr-2" />
                Start Free Trial
              </Button>
              <Button variant="outline" size="lg" className="text-lg px-8 py-6">
                <Video className="w-5 h-5 mr-2" />
                Watch Demo
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Product Showcase - Features Section */}
      <section id="features" className="py-20 bg-muted/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
              Four Powerful Products, One Platform
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              From live streaming to studio production, YohPal Mesh covers all your video creation needs.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {/* YohPal Mesh */}
            <Card className="group hover:shadow-xl transition-all duration-300 shadow-lg">
              <CardHeader className="text-center">
                <div className="w-16 h-16 bg-primary rounded-2xl mx-auto mb-4 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <Camera className="w-8 h-8 text-primary-foreground" />
                </div>
                <CardTitle className="text-xl">YohPal Mesh</CardTitle>
                <CardDescription>Multi-camera coordination and intelligent switching</CardDescription>
              </CardHeader>
            </Card>

            {/* YohPal Studio */}
            <Card className="group hover:shadow-xl transition-all duration-300">
              <CardHeader className="text-center">
                <div className="w-16 h-16 bg-secondary rounded-2xl mx-auto mb-4 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <Video className="w-8 h-8 text-secondary-foreground" />
                </div>
                <CardTitle className="text-xl">YohPal Studio</CardTitle>
                <CardDescription>Offline recording and professional editing tools</CardDescription>
              </CardHeader>
            </Card>

            {/* YohPal Live */}
            <Card className="group hover:shadow-xl transition-all duration-300 shadow-lg">
              <CardHeader className="text-center">
                <div className="w-16 h-16 bg-accent rounded-2xl mx-auto mb-4 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <Zap className="w-8 h-8 text-accent-foreground" />
                </div>
                <CardTitle className="text-xl">YohPal Live</CardTitle>
                <CardDescription>Real-time streaming to all major platforms</CardDescription>
              </CardHeader>
            </Card>

            {/* Production Cloud */}
            <Card className="group hover:shadow-xl transition-all duration-300 shadow-lg">
              <CardHeader className="text-center">
                <div className="w-16 h-16 bg-muted rounded-2xl mx-auto mb-4 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <Share2 className="w-8 h-8 text-muted-foreground" />
                </div>
                <CardTitle className="text-xl">Production Cloud</CardTitle>
                <CardDescription>Cloud processing and advanced AI features</CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* Key Features */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
              Revolutionary Features
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Professional filmmaking tools powered by AI and intelligent automation.
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div className="space-y-8">
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center flex-shrink-0">
                  <Smartphone className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-foreground mb-2">
                    AI Director Mode
                  </h3>
                  <p className="text-muted-foreground">
                    Intelligent camera switching based on speaker detection, movement tracking, and scene analysis.
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-secondary/10 rounded-xl flex items-center justify-center flex-shrink-0">
                  <Users className="w-6 h-6 text-secondary-foreground" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-foreground mb-2">
                    Multi-Device Sync
                  </h3>
                  <p className="text-muted-foreground">
                    Perfect synchronization across unlimited mobile devices with frame-accurate timing.
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-accent/10 rounded-xl flex items-center justify-center flex-shrink-0">
                  <Star className="w-6 h-6 text-accent-foreground" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-foreground mb-2">
                    Studio Quality Output
                  </h3>
                  <p className="text-muted-foreground">
                    Professional-grade video processing with automatic color correction and audio mixing.
                  </p>
                </div>
              </div>
            </div>

            <div className="relative">
              <div className="aspect-video bg-muted rounded-2xl flex items-center justify-center border-2 border-dashed border-border">
                <div className="text-center">
                  <Video className="w-16 h-16 text-muted-foreground mx-auto mb-4" />
                  <p className="text-muted-foreground">
                    Interactive Demo Coming Soon
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-muted/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
              Plans for Every Creator
            </h2>
            <p className="text-xl text-muted-foreground">
              Start free and scale as your production needs grow.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-5 gap-6">
            {/* FREE Plan */}
            <Card className="border-2 border-border shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center">
                <CardTitle className="text-xl">Free</CardTitle>
                <CardDescription className="text-sm">For testing</CardDescription>
                <div className="text-3xl font-bold text-foreground mt-4">
                  $0<span className="text-sm font-normal text-muted-foreground">/mo</span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>2 camera devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>1 director device</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Manual switching</span>
                </div>
                <Button variant="outline" className="w-full mt-4">Get Started</Button>
              </CardContent>
            </Card>

            {/* CREATOR Plan */}
            <Card className="border-2 border-border shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center">
                <CardTitle className="text-xl">Creator</CardTitle>
                <CardDescription className="text-sm">For solo creators</CardDescription>
                <div className="text-3xl font-bold text-foreground mt-4">
                  $9<span className="text-sm font-normal text-muted-foreground">/mo</span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>5 camera devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>1 director device</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Manual switching</span>
                </div>
                <Button className="w-full mt-4">Start Trial</Button>
              </CardContent>
            </Card>

            {/* PRO Plan */}
            <Card className="border-2 border-primary shadow-lg lg:scale-105 z-10">
              <CardHeader className="text-center">
                <Badge className="w-fit mx-auto mb-2">Popular</Badge>
                <CardTitle className="text-xl">Pro</CardTitle>
                <CardDescription className="text-sm">For professionals</CardDescription>
                <div className="text-3xl font-bold text-foreground mt-4">
                  $29<span className="text-sm font-normal text-muted-foreground">/mo</span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>10 camera devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>2 director devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>AI Assistant</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>SFU for streaming</span>
                </div>
                <Button className="w-full mt-4">Start Trial</Button>
              </CardContent>
            </Card>

            {/* STUDIO Plan */}
            <Card className="border-2 border-border shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center">
                <CardTitle className="text-xl">Studio</CardTitle>
                <CardDescription className="text-sm">For production teams</CardDescription>
                <div className="text-3xl font-bold text-foreground mt-4">
                  $99<span className="text-sm font-normal text-muted-foreground">/mo</span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>25 camera devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>5 director devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>AI Director</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Advanced AI features</span>
                </div>
                <Button variant="outline" className="w-full mt-4">Start Trial</Button>
              </CardContent>
            </Card>

            {/* ENTERPRISE Plan */}
            <Card className="border-2 border-border shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center">
                <CardTitle className="text-xl">Enterprise</CardTitle>
                <CardDescription className="text-sm">Custom solutions</CardDescription>
                <div className="text-3xl font-bold text-foreground mt-4">
                  Custom<span className="text-sm font-normal text-muted-foreground block">pricing</span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Unlimited devices</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Full AI suite</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>Priority support</span>
                </div>
                <div className="flex items-center space-x-2 text-sm">
                  <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
                  <span>SLA guaranteed</span>
                </div>
                <Button variant="outline" className="w-full mt-4">Contact Sales</Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-primary">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold text-primary-foreground mb-6">
            Ready to Transform Your Video Production?
          </h2>
          <p className="text-xl text-primary-foreground/80 mb-10 max-w-2xl mx-auto">
            Join creators worldwide who are making professional videos with just their smartphones.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" variant="secondary" className="text-lg px-8 py-6">
              <Play className="w-5 h-5 mr-2" />
              Get Started Free
            </Button>
            <Button size="lg" variant="outline" className="text-lg px-8 py-6 border-primary-foreground text-primary-foreground hover:bg-primary-foreground/10">
              Learn More
              <ArrowRight className="w-5 h-5 ml-2" />
            </Button>
          </div>
        </div>
      </section>

      {/* Footer - About Section */}
      <footer id="about" className="bg-card text-card-foreground py-16 border-t">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center">
            <div className="flex items-center space-x-2 mb-8 md:mb-0">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                <Camera className="w-5 h-5 text-primary-foreground" />
              </div>
              <span className="text-xl font-bold text-foreground">YohPal Mesh</span>
            </div>
            <div className="flex flex-wrap gap-8 text-sm text-muted-foreground">
              <a href="#" className="hover:text-foreground transition-colors">Privacy</a>
              <a href="#" className="hover:text-foreground transition-colors">Terms</a>
              <a href="#" className="hover:text-foreground transition-colors">Support</a>
              <a href="#" className="hover:text-foreground transition-colors">Contact</a>
            </div>
          </div>
          <div className="border-t border-border mt-8 pt-8 text-center text-muted-foreground">
            <p>&copy; 2026 YohPal Mesh. Transforming mobile phones into production studios.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
