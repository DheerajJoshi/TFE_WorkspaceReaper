resource "aws_s3_bucket" "visual_results" {
  count  = "${var.ui == true ? 1 : 0}"
  bucket = "workspacereaper-${var.TFE_ORG}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "getitall" {
  count  = "${var.ui == true ? 1 : 0}"
  bucket = "${aws_s3_bucket.visual_results.id}"

  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["${aws_s3_bucket.visual_results.arn}/*"]
    }
  ]
}
EOF
}

locals {
  files    = ["css/style-large.css", "css/style-small.css", "css/style-medium.css", "css/style-xlarge.css", "css/style-xsmall.css", "css/style.css", "css/font-awesome.min.css", "css/skel.css", "css/images/overlay.png", "css/ie/html5shiv.js", "css/ie/v9.css", "css/ie/v8.css", "css/ie/PIE.htc", "css/ie/backgroundsize.min.htc", "images/banner.jpg", "js/jquery.scrollgress.min.js", "js/jquery.scrolly.min.js", "js/jquery.dropotron.min.js", "js/jquery.min.js", "js/init.js", "js/skel.min.js", "js/skel-layers.min.js", "js/jquery.slidertron.min.js", "fonts/fontawesome-webfont.svg", "fonts/FontAwesome.otf", "fonts/fontawesome-webfont.ttf", "fonts/fontawesome-webfont.woff", "fonts/fontawesome-webfont.eot", "sass/style-xlarge.scss", "sass/_vars.scss", "sass/style-xsmall.scss", "sass/style.scss", "sass/style-medium.scss", "sass/_mixins.scss", "sass/style-large.scss", "sass/style-small.scss", "sass/ie/v8.scss", "sass/ie/v9.scss"]
  root_dir = "../functions/static/"

  contentType = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
  }
}

resource "aws_s3_bucket_object" "object" {
  count        = "${var.ui == true ? length(local.files) : 0}"
  bucket       = "${aws_s3_bucket.visual_results.id}"
  key          = "${local.files[count.index]}"
  source       = "${local.root_dir}${local.files[count.index]}"
  etag         = "${local.root_dir}${local.files[count.index]}"
  content_type = "${lookup(local.contentType,element(split(".",local.files[count.index]),1),"text/html")}"
}

data "template_file" "init" {
  count    = "${var.ui == true ? 1 : 0}"
  template = "${file("../functions/static/index.tpl")}"

  vars {
    rest_endpoint = "${aws_api_gateway_deployment.example.invoke_url}/${aws_api_gateway_resource.proxy.path_part}"
  }
}

resource "aws_s3_bucket_object" "rendered_index" {
  count        = "${var.ui == true ? 1 : 0}"
  bucket       = "${aws_s3_bucket.visual_results.id}"
  key          = "index.html"
  content      = "${data.template_file.init.rendered}"
  content_type = "text/html"
}
